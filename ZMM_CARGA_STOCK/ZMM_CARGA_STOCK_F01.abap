*&---------------------------------------------------------------------*
*&  Include           ZMM_CARGA_STOCK_F01
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------
*            A T   S E L E C T I O N  -  S C R E E N
*---------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR pfile.
  PERFORM get_filename CHANGING pfile.

*----------------------------------------------------------------------*
*            SUB - RUTINAS
*----------------------------------------------------------------------*
FORM get_filename CHANGING pfile.

  MOVE text-002 TO gs_title.
  REFRESH gti_file_table[].

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = gs_title
      default_extension       = cl_gui_frontend_services=>filetype_excel
      file_filter             = '*.XLS*'
    CHANGING
      file_table              = gti_file_table
      rc                      = gi_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.
  IF sy-subrc EQ 0.
    READ TABLE  gti_file_table INTO pfile INDEX 1.
    IF sy-subrc EQ 0.
      p_file = pfile.
    ENDIF.
  ELSE.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    "GET_FILENAME

*&---------------------------------------------------------------------*
*&      Form  GEN_PO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM gen_po.

  CALL METHOD obj_alv_grid->check_changed_data.

* Structures for BAPI
  DATA: gm_header  TYPE bapi2017_gm_head_01,
        gm_code    TYPE bapi2017_gm_code,
        gm_headret TYPE bapi2017_gm_head_ret,
        gm_item    TYPE TABLE OF bapi2017_gm_item_create WITH HEADER LINE,
        gm_return  TYPE bapiret2 OCCURS 0 WITH HEADER LINE,
        gm_retmtd  TYPE bapi2017_gm_head_ret-mat_doc.

  CLEAR: gm_return, gm_retmtd. REFRESH gm_return.

  DATA: lv_tabix TYPE sy-tabix.

  READ TABLE gt_data WITH KEY select = 'X' TRANSPORTING NO FIELDS.
  IF sy-subrc EQ 4.

    MESSAGE 'Debe selecionar al menos un registro' TYPE 'S' DISPLAY LIKE 'E'.

  ELSE.

    LOOP AT gt_data INTO gs_data WHERE select EQ 'X'.

      lv_tabix = sy-tabix.

*&---------------------------------------------------------------------*
*&                  G O O D S M V T _ H E A D E R
*&---------------------------------------------------------------------*
      CLEAR: gm_header.
      gm_header-pstng_date = gs_data-pstng_date.
      gm_header-doc_date   = gs_data-doc_date.
      gm_header-header_txt = gs_data-header_txt.


*&---------------------------------------------------------------------*
*&                  G M _ C O D E
*&---------------------------------------------------------------------*
      gm_code-gm_code = pgmcode.


*&---------------------------------------------------------------------*
*&                  G O O D S M V T _ I T E M
*&---------------------------------------------------------------------*
      CLEAR gm_item.
      gm_item-material   = gs_data-material.
      gm_item-plant      = gs_data-plant.
      gm_item-stge_loc   = gs_data-stge_loc.
      gm_item-move_type  = gs_data-move_type.
      gm_item-val_type   = gs_data-val_type.
      gm_item-batch      = gs_data-batch.
      gm_item-entry_qnt  = gs_data-entry_qnt.
      gm_item-entry_uom  = gs_data-entry_uom.
      gm_item-amount_lc  = gs_data-amount_lc.
      gm_item-stck_type  = gs_data-stck_type.
      gm_item-spec_stock = gs_data-spec_stock.
      gm_item-vendor     = gs_data-vendor.
      gm_item-customer   = gs_data-customer.
      gm_item-sales_ord  = gs_data-sales_ord.
      APPEND gm_item.


*&---------------------------------------------------------------------*
*&                  E X E C U T E   B A P I
*&---------------------------------------------------------------------*

      CALL FUNCTION 'BAPI_GOODSMVT_CREATE'
        EXPORTING
          goodsmvt_header  = gm_header
          goodsmvt_code    = gm_code
        IMPORTING
          goodsmvt_headret = gm_headret
          materialdocument = gm_retmtd
        TABLES
          goodsmvt_item    = gm_item
          return           = gm_return.


      IF NOT gm_retmtd IS INITIAL.
        COMMIT WORK AND WAIT.
        CALL FUNCTION 'DEQUEUE_ALL'.
        MOVE gm_retmtd TO gs_data-log.
        MODIFY gt_data FROM gs_data INDEX lv_tabix.
      ELSE.
        LOOP AT gm_return WHERE type EQ 'E'.
          CONCATENATE gm_return-type ':' gm_return-id ':' gm_return-number ` ` gm_return-message INTO gs_data-log.
          MODIFY gt_data FROM gs_data INDEX lv_tabix.
        ENDLOOP.
        COMMIT WORK AND WAIT.
        CALL FUNCTION 'DEQUEUE_ALL'.
      ENDIF.

    ENDLOOP.

  ENDIF.

  CALL METHOD obj_alv_grid->refresh_table_display.

ENDFORM.                    " GEN_PO
*&---------------------------------------------------------------------*
*&      Form  CHECK_MDATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_mdata.

  DATA:
        lt_marc TYPE TABLE OF marc,
        ls_marc TYPE marc,
        lt_mard TYPE TABLE OF mard,
        ls_mard TYPE mard,
        lt_mbew TYPE TABLE OF mbew,
        ls_mbew TYPE mbew.

  DATA:
        lt_styletab TYPE lvc_t_styl,
        ls_stylerow TYPE lvc_s_styl.

  DATA:
        lv_tabix TYPE c.

  SELECT * FROM marc INTO TABLE lt_marc
    FOR ALL ENTRIES IN gt_data
      WHERE matnr EQ gt_data-material
        AND werks EQ gt_data-plant.

  SELECT * FROM mard INTO TABLE lt_mard
    FOR ALL ENTRIES IN gt_data
      WHERE matnr EQ gt_data-material
        AND werks EQ gt_data-plant
        AND lgort EQ gt_data-stge_loc.

  SELECT * FROM mbew INTO TABLE lt_mbew
    FOR ALL ENTRIES IN gt_data
      WHERE matnr EQ gt_data-material
        AND bwkey EQ gt_data-plant.


  LOOP AT gt_data ASSIGNING <gfs_data>.

    lv_tabix = sy-tabix.

    READ TABLE lt_marc INTO ls_marc WITH KEY matnr = <gfs_data>-material werks = <gfs_data>-plant.
    IF sy-subrc EQ 0.
      <gfs_data>-status = gc_green. "icon_green_light.

      READ TABLE lt_mard INTO ls_mard WITH KEY matnr = <gfs_data>-material werks = <gfs_data>-plant lgort = <gfs_data>-stge_loc.
      IF sy-subrc EQ 0.
        <gfs_data>-status = gc_green. "icon_green_light.
      ELSE.
        <gfs_data>-status = gc_red.
        ls_stylerow-fieldname = 'SELECT'.
        ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
        IF <gfs_data>-field_style IS INITIAL.
          APPEND ls_stylerow  TO <gfs_data>-field_style.
        ENDIF.
        CONCATENATE 'Material' <gfs_data>-material 'no existe en almacen' <gfs_data>-stge_loc INTO <gfs_data>-log SEPARATED BY space.
        CONTINUE.
      ENDIF.

    ELSE.
      <gfs_data>-status = gc_red.
      ls_stylerow-fieldname = 'SELECT'.
      ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
      IF <gfs_data>-field_style IS INITIAL.
        APPEND ls_stylerow  TO <gfs_data>-field_style.
      ENDIF.
      CONCATENATE 'Material' <gfs_data>-material 'no existe en centro' <gfs_data>-plant INTO <gfs_data>-log SEPARATED BY space.
      CONTINUE.
    ENDIF.

    READ TABLE lt_mbew INTO ls_mbew WITH KEY matnr = <gfs_data>-material bwkey = <gfs_data>-plant.
    IF ls_mbew-vprsv EQ <gfs_data>-vprsv.
      <gfs_data>-status = gc_green.
    ELSE.
      <gfs_data>-status = gc_red.
      ls_stylerow-fieldname = 'SELECT'.
      ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
      IF <gfs_data>-field_style IS INITIAL.
        APPEND ls_stylerow  TO <gfs_data>-field_style.
      ENDIF.
      CONCATENATE 'Material' <gfs_data>-material 'no coincide con el control de precio:' <gfs_data>-vprsv INTO <gfs_data>-log SEPARATED BY space.
      CONTINUE.
    ENDIF.

    IF ls_mbew-mlast EQ <gfs_data>-mlast.
      <gfs_data>-status = gc_green.
    ELSE.
      <gfs_data>-status = gc_red.
      ls_stylerow-fieldname = 'SELECT'.
      IF <gfs_data>-field_style IS INITIAL.
        APPEND ls_stylerow  TO <gfs_data>-field_style.
      ENDIF.
      CONCATENATE 'Material' <gfs_data>-material 'no coincide con la determinacion de precio:' <gfs_data>-mlast INTO <gfs_data>-log SEPARATED BY space.
      CONTINUE.
    ENDIF.

  ENDLOOP.

ENDFORM.                    " CHECK_MDATA

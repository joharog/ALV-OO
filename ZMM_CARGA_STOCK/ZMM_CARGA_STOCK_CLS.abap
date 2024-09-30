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

  DATA: lv_tabix TYPE sy-tabix,
        lv_count TYPE char10,
        lv_log   TYPE string,
        ls_mara  TYPE mara.

  CLEAR: gm_return, gm_retmtd, lv_tabix, lv_count. REFRESH gm_return.

  READ TABLE gt_data WITH KEY select = 'X' TRANSPORTING NO FIELDS.
  IF sy-subrc EQ 4.

    MESSAGE 'Debe selecionar al menos un registro' TYPE 'S' DISPLAY LIKE 'E'.

  ELSE.
    UNASSIGN <gfs_data>.
    LOOP AT gt_data ASSIGNING <gfs_data> WHERE select EQ 'X' AND log IS INITIAL.

*      Contador de posiciones selecionadas
      IF lv_count IS INITIAL.
        lv_count = 1.
      ELSE.
        <gfs_data>-sel_pos = lv_count = lv_count + 1.
      ENDIF.




*&---------------------------------------------------------------------*
*&                  G O O D S M V T _ H E A D E R
*&---------------------------------------------------------------------*
      CLEAR: gm_header.
      gm_header-pstng_date = <gfs_data>-pstng_date.
      gm_header-doc_date   = <gfs_data>-doc_date.
      gm_header-header_txt = <gfs_data>-header_txt.


*&---------------------------------------------------------------------*
*&                  G M _ C O D E
*&---------------------------------------------------------------------*
      gm_code-gm_code = pgmcode.


*&---------------------------------------------------------------------*
*&                  G O O D S M V T _ I T E M
*&---------------------------------------------------------------------*
      gm_item-material   = <gfs_data>-material.
      gm_item-plant      = <gfs_data>-plant.
      gm_item-stge_loc   = <gfs_data>-stge_loc.
      gm_item-move_type  = <gfs_data>-move_type.
      gm_item-val_type   = <gfs_data>-val_type.
      gm_item-batch      = <gfs_data>-batch.
      gm_item-entry_qnt  = <gfs_data>-entry_qnt.
      gm_item-amount_lc  = <gfs_data>-amount_lc.
      gm_item-stck_type  = <gfs_data>-stck_type.
      gm_item-spec_stock = <gfs_data>-spec_stock.
      gm_item-vendor     = <gfs_data>-vendor.
      gm_item-customer   = <gfs_data>-customer.
      gm_item-sales_ord  = <gfs_data>-sales_ord.

      SELECT SINGLE * FROM mara
        INTO ls_mara
        WHERE matnr EQ gs_data-material.
      IF sy-subrc EQ 0.

        CALL FUNCTION 'CONVERSION_EXIT_CUNIT_INPUT'
          EXPORTING
            input    = ls_mara-meins
            language = sy-langu
          IMPORTING
            output   = gm_item-entry_uom.
      ENDIF.
*      gm_item-entry_uom  = gs_data-entry_uom.

      APPEND gm_item.
      CLEAR: gm_item, gs_data.

    ENDLOOP.

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

    CLEAR: lv_tabix, lv_log, lv_tabix.
    IF NOT gm_retmtd IS INITIAL.
      COMMIT WORK AND WAIT.
      CALL FUNCTION 'DEQUEUE_ALL'.

      LOOP AT gt_data INTO gs_data WHERE select EQ 'X' AND log IS INITIAL.
        lv_tabix = sy-tabix.
        MOVE gm_retmtd TO gs_data-log.
        MOVE '' TO gs_data-select.
        ls_stylerow-fieldname = 'SELECT'.
        ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
        IF gs_data-field_style IS INITIAL.
          APPEND ls_stylerow  TO gs_data-field_style.
        ENDIF.
        MODIFY gt_data FROM gs_data INDEX lv_tabix.
      ENDLOOP.

    ELSE.

      LOOP AT gm_return WHERE type EQ 'E'.

        CONCATENATE gm_return-type ':' gm_return-id ':' gm_return-number ` ` gm_return-message INTO gs_data-log.

        MOVE '' TO gs_data-select.
        gs_data-status = gc_red.
        ls_stylerow-fieldname = 'SELECT'.
        ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
        IF gs_data-field_style IS INITIAL.
          APPEND ls_stylerow  TO gs_data-field_style.
        ENDIF.

        MODIFY gt_data FROM gs_data TRANSPORTING log status field_style WHERE select EQ 'X' AND sel_pos EQ gm_return-row.
        CLEAR: gs_data-log, gs_data-select, gs_data-field_style.

      ENDLOOP.

*      LOOP AT gt_data INTO gs_data WHERE select EQ 'X' AND log IS INITIAL.
*        lv_tabix = sy-tabix.
*        MOVE lv_log TO gs_data-log.
*        MOVE '' TO gs_data-select.
*        gs_data-status = gc_red.
*        ls_stylerow-fieldname = 'SELECT'.
*        ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
*        IF gs_data-field_style IS INITIAL.
*          APPEND ls_stylerow  TO gs_data-field_style.
*        ENDIF.
*        MODIFY gt_data FROM gs_data INDEX lv_tabix.
*      ENDLOOP.

      COMMIT WORK AND WAIT.
      CALL FUNCTION 'DEQUEUE_ALL'.
    ENDIF.

    CLEAR: gm_header, gm_code, gm_headret, gm_retmtd, gm_item, gm_return.
    REFRESH: gm_item, gm_return.

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

  CLEAR: ls_stylerow.
  REFRESH: lt_styletab.

  LOOP AT gt_data ASSIGNING <gfs_data>.

    lv_tabix = sy-tabix.

    READ TABLE lt_marc INTO ls_marc WITH KEY matnr = <gfs_data>-material werks = <gfs_data>-plant.
    IF sy-subrc EQ 0.
      <gfs_data>-status = gc_green. "icon_green_light.

      READ TABLE lt_mard INTO ls_mard WITH KEY matnr = <gfs_data>-material werks = <gfs_data>-plant lgort = <gfs_data>-stge_loc.
      IF sy-subrc EQ 0.
        <gfs_data>-status = gc_green. "icon_green_light.
      ELSE.

        IF <gfs_data>-spec_stock IS NOT INITIAL AND <gfs_data>-vendor IS NOT INITIAL.
          <gfs_data>-status = gc_green.
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

*    Deshabilitar validacion para Control de Precios 15.08.2024
*    READ TABLE lt_mbew INTO ls_mbew WITH KEY matnr = <gfs_data>-material bwkey = <gfs_data>-plant.
*    IF ls_mbew-vprsv EQ <gfs_data>-vprsv.
*      <gfs_data>-status = gc_green.
*    ELSE.
*      <gfs_data>-status = gc_red.
*      ls_stylerow-fieldname = 'SELECT'.
*      ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
*      IF <gfs_data>-field_style IS INITIAL.
*        APPEND ls_stylerow  TO <gfs_data>-field_style.
*      ENDIF.
*      CONCATENATE 'Material' <gfs_data>-material 'no coincide con el control de precio:' <gfs_data>-vprsv INTO <gfs_data>-log SEPARATED BY space.
*      CONTINUE.
*    ENDIF.

*    Deshabilitar validacion para Determ.precio 15.08.2024
*    IF ls_mbew-mlast EQ <gfs_data>-mlast.
*      <gfs_data>-status = gc_green.
*    ELSE.
*      <gfs_data>-status = gc_red.
*      ls_stylerow-fieldname = 'SELECT'.
*      IF <gfs_data>-field_style IS INITIAL.
*        APPEND ls_stylerow  TO <gfs_data>-field_style.
*      ENDIF.
*      CONCATENATE 'Material' <gfs_data>-material 'no coincide con la determinacion de precio:' <gfs_data>-mlast INTO <gfs_data>-log SEPARATED BY space.
*      CONTINUE.
*    ENDIF.

  ENDLOOP.

ENDFORM.                    " CHECK_MDATA

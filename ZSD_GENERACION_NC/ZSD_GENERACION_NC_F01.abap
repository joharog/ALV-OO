*&---------------------------------------------------------------------*
*& Include          ZSD_GENERACION_NC_F01
*&---------------------------------------------------------------------*


*---------------------------------------------------------------------
*            I N I T I A L I Z A T I O N
*---------------------------------------------------------------------
INITIALIZATION.
  SELECT SINGLE * FROM zparamdocsd INTO gs_tabdoc.


*---------------------------------------------------------------------
*            A T   S E L E C T I O N  -  S C R E E N
*---------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  PERFORM get_filename CHANGING p_file.


AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF screen-name = 'P_KSCHL'.
      screen-input = 0.
      MODIFY SCREEN.
    ENDIF.
  ENDLOOP.

*----------------------------------------------------------------------*
*      Form  GET_FILENAME
*----------------------------------------------------------------------*
FORM get_filename CHANGING p_file.

  MOVE TEXT-002 TO gs_title.
  REFRESH gs_filetab[].

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = gs_title
      default_extension       = cl_gui_frontend_services=>filetype_excel
      file_filter             = '*.XLS*'
    CHANGING
      file_table              = gs_filetab
      rc                      = gi_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.
  IF sy-subrc EQ 0.
    READ TABLE gs_filetab INTO p_file INDEX 1.
    IF sy-subrc EQ 0.
      file = p_file.
    ENDIF.
  ELSE.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    "GET_FILENAME

*&---------------------------------------------------------------------*
*&      Form  GEN_SO
*&---------------------------------------------------------------------*
FORM gen_so.

  DATA: ls_header      TYPE bapisdhd1,
        ls_headerx     TYPE bapisdhd1x,
        lt_items       TYPE TABLE OF bapisditm,
        lt_itemsx      TYPE TABLE OF bapisditmx,
        lt_partners    TYPE TABLE OF bapiparnr,
        lt_conditions  TYPE TABLE OF bapicond,
        lt_conditionsx TYPE TABLE OF bapicondx,
        lt_return      TYPE TABLE OF bapiret2.

  UNASSIGN <gfs_alv>.
  REFRESH: gt_return.

  LOOP AT gt_alv ASSIGNING <gfs_alv> WHERE check EQ abap_true AND vbeln_so IS INITIAL.

    <gfs_alv>-matnr = |{ <gfs_alv>-matnr ALPHA = IN }|.
    <gfs_alv>-kunnr = |{ <gfs_alv>-kunnr ALPHA = IN }|.

    ls_header = VALUE #( refobjtype = gs_tabdoc-doc_type
                         doc_type   = gs_tabdoc-doc_type
                         sales_org  = <gfs_alv>-vkorg
                         distr_chan = <gfs_alv>-vtweg
                         division   = <gfs_alv>-spart
                         ord_reason = <gfs_alv>-augru
                         price_date = sy-datum
                         ref_doc    = <gfs_alv>-vbeln_fa
                         ref_doc_l  = <gfs_alv>-vbeln_fa
                         purch_no_c = <gfs_alv>-bstkd
                         purch_no_s = <gfs_alv>-bstkd
                         refdoc_cat = 'M'
                         bill_date  = sy-datum
                         serv_date  = sy-datum ).

    ls_headerx = VALUE #( doc_type   = gc_x
                          sales_org  = gc_x
                          distr_chan = gc_x
                          division   = gc_x
                          ord_reason = gc_x
                          price_date = gc_x
                          ref_doc    = gc_x
                          ref_doc_l  = gc_x
                          purch_no_c = gc_x
                          purch_no_s = gc_x
                          refdoc_cat = gc_x
                          bill_date  = gc_x
                          serv_date  = gc_x ).

    APPEND VALUE #( itm_number = 000001
                    material   = <gfs_alv>-matnr
                    bill_date  = sy-datum
                    target_qty = <gfs_alv>-kwmeng )
                    TO lt_items.

    APPEND VALUE #( itm_number = 000001
                    material   = gc_x
                    bill_date  = gc_x
                    target_qty = gc_x )
                    TO lt_itemsx.

    APPEND VALUE #( partn_role = 'AG'
                    partn_numb = <gfs_alv>-kunnr )
                    TO lt_partners.

    APPEND VALUE #( itm_number = 000001
                    cond_st_no = 001
                    cond_count = 01
                    cond_type  = p_kschl
                    cond_value = <gfs_alv>-imp_net
                    currency   = <gfs_alv>-waerk )
                    TO lt_conditions.

    APPEND VALUE #( itm_number = 000001
                    cond_st_no = 001
                    cond_count = 01
                    cond_type  = p_kschl
                    cond_value = gc_x
                    currency   = gc_x )
                    TO lt_conditionsx.

    CALL FUNCTION 'SD_SALESDOCUMENT_CREATE'
      EXPORTING
        sales_header_in       = ls_header
        sales_header_inx      = ls_headerx
        status_buffer_refresh = abap_true
        i_refresh_v45i        = abap_true
      TABLES
        return                = lt_return
        sales_items_in        = lt_items
        sales_items_inx       = lt_itemsx
        sales_partners        = lt_partners
        sales_conditions_in   = lt_conditions
        sales_conditions_inx  = lt_conditionsx.
    IF sy-subrc EQ 0.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      READ TABLE lt_return INTO DATA(ls_return) WITH KEY id = 'V1'. "number = 311.
      IF ls_return-number EQ 311.

        <gfs_alv>-vbeln_so = |{ ls_return-message_v2 ALPHA = IN }|.
*        <gfs_alv>-t_icon = icon_led_green.

        SELECT SINGLE ernam erdat erzet FROM vbak INTO ( <gfs_alv>-ernam, <gfs_alv>-erdat, <gfs_alv>-erzet )
         WHERE vbeln EQ <gfs_alv>-vbeln_so.

        APPEND ls_return TO gt_return.

      ELSE.
        IF ls_return IS INITIAL.
          READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
          <gfs_alv>-vbeln_so = icon_led_red.
          APPEND ls_return TO gt_return.
        ELSE.
          <gfs_alv>-vbeln_so = icon_led_red.
          APPEND ls_return TO gt_return.
        ENDIF.
      ENDIF.
    ENDIF.

    CLEAR: ls_header, ls_headerx, ls_return.
    REFRESH: lt_return, lt_items, lt_itemsx, lt_partners, lt_conditions, lt_conditionsx.
  ENDLOOP.

  CALL METHOD obj_alv_grid->refresh_table_display.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  GEN_PO
*&---------------------------------------------------------------------*
FORM gen_nc.

  CALL METHOD obj_alv_grid->check_changed_data.

  DATA: lt_billingdatain TYPE TABLE OF bapivbrk,
        lt_errors        TYPE TABLE OF bapivbrkerrors,
        lt_return        TYPE TABLE OF bapiret1,
        lt_success       TYPE TABLE OF bapivbrksuccess.

  UNASSIGN: <gfs_alv>.
  REFRESH: gt_return.

  LOOP AT gt_alv ASSIGNING <gfs_alv> WHERE check EQ abap_true AND vbeln_nc IS INITIAL. "OR vbeln_so NE icon_led_red ).

    IF <gfs_alv>-vbeln_so EQ icon_led_red.
      CONTINUE.

    ELSE.
      SELECT SINGLE vbtyp FROM vbak INTO @DATA(lv_vbtyp)
        WHERE vbeln EQ @<gfs_alv>-vbeln_so.

      APPEND VALUE #( doc_type   = gs_tabdoc-doc_type_fact
                      bill_date  = gv_fkdat
                      sold_to    = <gfs_alv>-kunnr
                      bill_to    = <gfs_alv>-kunrg
                      payer      = <gfs_alv>-kunrg
                      ref_doc    = <gfs_alv>-vbeln_so
                      ref_doc_ca = lv_vbtyp )
                      TO lt_billingdatain.

      CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
        TABLES
          billingdatain = lt_billingdatain
          errors        = lt_errors
          return        = lt_return
          success       = lt_success.

      IF sy-subrc EQ 0.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

        READ TABLE lt_success INTO DATA(ls_success) WITH KEY ref_doc = <gfs_alv>-vbeln_so.
        IF sy-subrc EQ 0.
          <gfs_alv>-vbeln_nc = |{ ls_success-bill_doc ALPHA = IN }|.
*        APPEND ls_return TO gt_return.
          READ TABLE lt_return INTO DATA(ls_return) WITH KEY type = 'S'.
          IF ls_return-number EQ 311.
            APPEND ls_return TO gt_return.
          ENDIF.

        ENDIF.

        READ TABLE lt_errors INTO DATA(ls_errors) INDEX 1.
        IF sy-subrc EQ 0.
          READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
          <gfs_alv>-vbeln_nc = icon_led_red.
          APPEND ls_return TO gt_return.
        ENDIF.
      ENDIF.
    ENDIF.

    REFRESH: lt_billingdatain, lt_errors, lt_return, lt_success.
    CLEAR: ls_success, ls_return, ls_errors.
  ENDLOOP.

  CALL METHOD obj_alv_grid->refresh_table_display.

ENDFORM.                    " GEN_NC

*&---------------------------------------------------------------------*
*& Include          ZSD_GENERACION_NC_F01
*&---------------------------------------------------------------------*


*---------------------------------------------------------------------
*            I N I T I A L I Z A T I O N
*---------------------------------------------------------------------
INITIALIZATION.
  SELECT SINGLE * FROM ztsd_doc_fact INTO gs_doc_fact.


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
FORM gen_pv.

  DATA: ls_header     TYPE bapisdhd1,
        ls_headerx    TYPE bapisdhd1x,
        lv_sales_doc  TYPE bapivbeln-vbeln,
        lt_return     TYPE TABLE OF bapiret2,
        lt_items      TYPE TABLE OF bapisditm,
        lt_itemsx     TYPE TABLE OF bapisditmx,
        lt_partners   TYPE TABLE OF bapiparnr,
        lt_schedules  TYPE TABLE OF bapischdl,
        lt_schedulesx TYPE TABLE OF bapischdlx.



  UNASSIGN <gfs_alv>.
  REFRESH: gt_return.

  LOOP AT gt_alv ASSIGNING <gfs_alv> WHERE check EQ abap_true AND vbeln_pv IS INITIAL.

    <gfs_alv>-matnr = |{ <gfs_alv>-matnr ALPHA = IN }|.
    <gfs_alv>-kunnr = |{ <gfs_alv>-kunnr ALPHA = IN }|.

    ls_header = VALUE #( refobjtype = gs_doc_fact-doc_type
                         doc_type   = gs_doc_fact-doc_type
                         sales_org  = <gfs_alv>-vkorg
                         distr_chan = <gfs_alv>-vtweg
                         division   = <gfs_alv>-spart
                         sales_off  = <gfs_alv>-vkbur
                         req_date_h = sy-datum
                         purch_date = sy-datum
                         price_date = sy-datum
                         purch_no_c = <gfs_alv>-bstkd
                         purch_no_s = <gfs_alv>-bstkd
                         bill_date  = sy-datum
                         serv_date  = sy-datum ).

    ls_headerx = VALUE #( doc_type   = gc_x
                          sales_org  = gc_x
                          distr_chan = gc_x
                          division   = gc_x
                          req_date_h = gc_x
                          purch_date = gc_x
                          price_date = gc_x
                          purch_no_c = gc_x
                          purch_no_s = gc_x
                          bill_date  = gc_x
                          serv_date  = gc_x ).

    APPEND VALUE #( partn_role = 'AG'
                    partn_numb = <gfs_alv>-kunnr )
                    TO lt_partners.

    APPEND VALUE #( partn_role = 'WE'
                    partn_numb = <gfs_alv>-kunnr )
                    TO lt_partners.

    LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<t_alv>) WHERE check EQ abap_true AND vbeln_pv IS INITIAL AND t_pos EQ <gfs_alv>-t_pos.

      APPEND VALUE #( itm_number = <t_alv>-itm_number     "Posicion
                      material   = <t_alv>-matnr          "Material
                      batch      = <t_alv>-batch          "Lote
                      plant      = <t_alv>-plant          "Centro
                      store_loc  = <t_alv>-store_loc      "Almacen
                      target_qty = <t_alv>-target_qty     "Cantidad
                      target_qu  = <t_alv>-target_qu      "UM
                      ship_point = <t_alv>-ship_point     "P. Expedicion
                      route      = <t_alv>-route )        "Rura
                      TO lt_items.
*
      APPEND VALUE #( itm_number = <t_alv>-itm_number
                      material   = gc_x
                      batch      = gc_x
                      plant      = gc_x
                      store_loc  = gc_x
                      target_qty = gc_x
                      target_qu  = gc_x
                      ship_point = gc_x
                      route      = gc_x )
                      TO lt_itemsx.

      APPEND VALUE #( itm_number = <t_alv>-itm_number
                      req_qty    = <t_alv>-target_qty )
                      TO lt_schedules.

      APPEND VALUE #( itm_number = <t_alv>-itm_number
                      req_qty    = gc_x )
                      TO lt_schedulesx.

    ENDLOOP.


    CALL FUNCTION 'BAPI_SALESORDER_CREATEFROMDAT2'
      EXPORTING
        order_header_in      = ls_header
        order_header_inx     = ls_headerx
      IMPORTING
        salesdocument        = lv_sales_doc
      TABLES
        return               = lt_return
        order_items_in       = lt_items
        order_items_inx      = lt_itemsx
        order_partners       = lt_partners
        order_schedules_in   = lt_schedules
        order_conditions_inx = lt_schedulesx.
    IF sy-subrc EQ 0.

      CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
        EXPORTING
          wait = abap_true.

      READ TABLE lt_return INTO DATA(ls_return) WITH KEY id = 'V1'.
      IF ls_return-number EQ 260.

        LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<z_alv>) WHERE t_pos EQ <gfs_alv>-t_pos.
          <z_alv>-vbeln_en = |{ ls_return-message_v3 ALPHA = IN }|.
          <z_alv>-vbeln_pv = |{ lv_sales_doc ALPHA = IN }|.
*          <z_alv>-t_entrega = |{ lv_sales_doc ALPHA = IN }|.
*        <gfs_alv>-t_icon = icon_led_green.

          SELECT SINGLE ernam erdat erzet FROM vbak INTO ( <z_alv>-ernam_pv, <z_alv>-erdat_pv, <z_alv>-erzet_pv )
           WHERE vbeln EQ <z_alv>-vbeln_pv.

          APPEND ls_return TO gt_return.
        ENDLOOP.
*
      ELSE.
        IF ls_return IS INITIAL.
          READ TABLE lt_return INTO ls_return WITH KEY type = 'E'.
          LOOP AT gt_alv ASSIGNING <z_alv> WHERE t_pos EQ <gfs_alv>-t_pos.
            <gfs_alv>-vbeln_pv = icon_led_red.
            APPEND ls_return TO gt_return.
          ENDLOOP.
        ELSE.
          LOOP AT gt_alv ASSIGNING <z_alv> WHERE t_pos EQ <gfs_alv>-t_pos.
            <gfs_alv>-vbeln_pv = icon_led_red.
            APPEND ls_return TO gt_return.
          ENDLOOP.
        ENDIF.
      ENDIF.
    ENDIF.
*
    CLEAR: ls_header, ls_headerx, lv_sales_doc, ls_return.
    REFRESH: lt_return, lt_items, lt_itemsx, lt_partners, lt_schedules, lt_schedulesx.
    UNASSIGN: <t_alv>, <z_alv>.
  ENDLOOP.

  CALL METHOD obj_alv_grid->refresh_table_display.

ENDFORM.


*&---------------------------------------------------------------------*
*&      Form  GEN_PO
*&---------------------------------------------------------------------*
FORM con_pv.

  CALL METHOD obj_alv_grid->check_changed_data.

  DATA: header_data    TYPE bapiobdlvhdrcon,
        header_control TYPE bapiobdlvhdrctrlcon,
        delivery       TYPE bapiobdlvhdrcon-deliv_numb,
        lt_return      TYPE TABLE OF bapiret2.

  UNASSIGN: <gfs_alv>.
  REFRESH: gt_return.

  LOOP AT gt_alv ASSIGNING <gfs_alv> WHERE check EQ abap_true AND vbeln_en IS NOT INITIAL AND t_entrega IS INITIAL.

    IF <gfs_alv>-vbeln_pv EQ icon_led_red.
      CONTINUE.

    ELSE.

      header_data = VALUE #( deliv_numb = <gfs_alv>-vbeln_en ).

      header_control = VALUE #( deliv_numb = <gfs_alv>-vbeln_en
                                post_gi_flg = gc_x ).

      delivery = <gfs_alv>-vbeln_en.

      CALL FUNCTION 'BAPI_OUTB_DELIVERY_CONFIRM_DEC'
        EXPORTING
          header_data    = header_data
          header_control = header_control
          delivery       = delivery
        TABLES
          return         = lt_return.

      IF sy-subrc EQ 0.

        WAIT UP TO 3 SECONDS.

        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

        LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<z_alv>) WHERE t_pos EQ <gfs_alv>-t_pos.
          IF lt_return[] IS INITIAL.

            <z_alv>-t_entrega = <z_alv>-vbeln_en.
*            <gfs_alv>-vbeln_en = <gfs_alv>-t_entrega.

            APPEND VALUE #( type       = 'I'
                            id         = 'ZMSG_GENDOCS'
                            number     = 005
                            message_v1 = <z_alv>-vbeln_en )
                            TO gt_return.

          ELSE.

            READ TABLE lt_return INTO DATA(ls_return) WITH KEY type = 'E'.
            IF ls_return-number EQ 602.

              APPEND VALUE #( type       = 'E'
                              id         = 'ZMSG_GENDOCS'
                              number     = 004
                              message_v1 = <z_alv>-vbeln_en )
                              TO gt_return.
              <z_alv>-vbeln_en = icon_led_red.
*              <gfs_alv>-vbeln_en = icon_led_red.

            ELSE.
              APPEND ls_return TO gt_return.
              <z_alv>-vbeln_en = icon_led_red.
*              <gfs_alv>-vbeln_en = icon_led_red.

            ENDIF.
          ENDIF.

        ENDLOOP.
      ENDIF.
    ENDIF.

    REFRESH: lt_return.
    CLEAR: ls_return, header_data, header_control, delivery.
    UNASSIGN: <z_alv>.
  ENDLOOP.

  CALL METHOD obj_alv_grid->refresh_table_display.

ENDFORM.                    " GEN_NC


*&---------------------------------------------------------------------*
*&      Form  GEN_FACT
*&---------------------------------------------------------------------*
FORM gen_fact.

  CALL METHOD obj_alv_grid->check_changed_data.

  DATA: billingdatain TYPE TABLE OF bapivbrk,
        lt_return     TYPE TABLE OF bapiret1,
        lt_errors     TYPE TABLE OF bapivbrkerrors,
        lt_success    TYPE TABLE OF bapivbrksuccess.

  UNASSIGN: <gfs_alv>.
  REFRESH: gt_return.

  LOOP AT gt_alv ASSIGNING <gfs_alv> WHERE check EQ abap_true AND vbeln_fc IS INITIAL.

    IF <gfs_alv>-vbeln_pv EQ icon_led_red AND <gfs_alv>-vbeln_en IS INITIAL.
      CONTINUE.

    ELSE.

      APPEND VALUE #( doc_type  = gs_doc_fact-doc_type_fact
                      bill_date = gv_fkdat
                      sold_to   = <gfs_alv>-kunnr
                      plant     = <gfs_alv>-plant
*                      bill_to   = <gfs_alv>-kunnr
*                      payer     = <gfs_alv>-kunnr
                      ref_doc   = <gfs_alv>-vbeln_pv
                      ref_doc_ca = gc_x )
*                      material  = <gfs_alv>-matnr
                      TO billingdatain.

      CALL FUNCTION 'BAPI_BILLINGDOC_CREATEMULTIPLE'
*        EXPORTING
*          posting       = 'X'
        TABLES
          billingdatain = billingdatain
          errors        = lt_errors
          return        = lt_return
          success       = lt_success.

      IF sy-subrc EQ 0.
        CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
          EXPORTING
            wait = abap_true.

        LOOP AT gt_alv ASSIGNING FIELD-SYMBOL(<z_alv>) WHERE t_pos EQ <gfs_alv>-t_pos.

          READ TABLE lt_return INTO DATA(ls_return) WITH KEY type = 'E'.
          IF sy-subrc EQ 0.
            <z_alv>-vbeln_fc = icon_led_red.
            APPEND ls_return TO gt_return.

          ELSE.
            READ TABLE lt_success INTO DATA(ls_success) WITH KEY ref_doc = <gfs_alv>-vbeln_pv.

            IF sy-subrc EQ 0.
              READ TABLE lt_return INTO ls_return WITH KEY type = 'S'.

              IF ls_return-number EQ 311.
                APPEND ls_return TO gt_return.
                <z_alv>-vbeln_fc = |{ ls_success-bill_doc ALPHA = IN }|.
              ENDIF.

            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDIF.

    REFRESH: lt_return, lt_errors, lt_success, billingdatain.
    CLEAR: ls_return, ls_success.

  ENDLOOP.

  CALL METHOD obj_alv_grid->refresh_table_display.

ENDFORM.                    " GEN_FACT

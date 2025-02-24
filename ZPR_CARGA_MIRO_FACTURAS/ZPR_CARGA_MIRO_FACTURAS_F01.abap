*&---------------------------------------------------------------------*
*& Include          ZPR_CARGA_MIRO_FACTURAS_F01
*&---------------------------------------------------------------------*
CLASS lcl_alv IMPLEMENTATION.
  METHOD get_excel_data.
    "Get Excel data
    it_worksheets = zcl_abap_util=>xls_to_itab( p_file ).
    DELETE it_worksheets FROM 2.
  ENDMETHOD.

  METHOD show_alv.
    TRY.
        CHECK it_worksheets IS NOT INITIAL.
        DATA(ls_worksheet) = it_worksheets[ 1 ].

        FIELD-SYMBOLS <it_worksheet> TYPE STANDARD TABLE.
        ASSIGN ls_worksheet-itab->* TO <it_worksheet>.

        LOOP AT <it_worksheet> ASSIGNING FIELD-SYMBOL(<fs_line>) FROM c_from.
          APPEND INITIAL LINE TO it_alv ASSIGNING FIELD-SYMBOL(<fs_record>).
          zcl_abap_util=>move_fields(
            CHANGING
              cs_line   = <fs_line>
              cs_record = <fs_record>
          ).
        ENDLOOP.

        IF osalv IS INITIAL.
          cl_salv_table=>factory(
            IMPORTING
              r_salv_table = osalv
            CHANGING
              t_table      = it_alv
          ).

          DATA key  TYPE salv_s_layout_key.
          key-report = sy-repid.
          key-handle = '1'.

          DATA(olayout) = osalv->get_layout( ).
          olayout->set_key( key ).
          olayout->set_save_restriction( if_salv_c_layout=>restrict_none ).
          olayout->set_initial_layout( '/DEFAULT' ).

          DATA(ofunctions) = osalv->get_functions( ).
          ofunctions->set_default( abap_true )." set_all( abap_true ).
*        ofunctions->set_all( abap_true ).
          DATA(odisplay) = osalv->get_display_settings( ).
          odisplay->set_striped_pattern( cl_salv_display_settings=>true ).

          DATA(ocols) = osalv->get_columns( ).
          ocols->set_key_fixation( abap_true ).
          ocols->set_optimize( abap_true ).
          osalv->get_selections( )->set_selection_mode( if_salv_c_selection_mode=>multiple ).

          DATA ocol TYPE REF TO cl_salv_column_table.
          DATA ls_color TYPE lvc_s_colo.
          ls_color-col = 5.
          TRY.
              ocol ?= ocols->get_column( 'INVOICE_ID' ).
              ocol->set_key( abap_true ).
              ocol ?= ocols->get_column( 'PO_ITEM' ).
              ocol->set_key( abap_true ).
              ocol ?= ocols->get_column( 'GROSS_AMOUNT' ).
              ocol->set_color( ls_color ).
              ocol ?= ocols->get_column( 'ITEM_AMOUNT' ).
              ocol->set_color( ls_color ).
            CATCH cx_salv_not_found ##NO_HANDLER.
          ENDTRY.

          DATA(oevents) = osalv->get_event( ).
          SET HANDLER on_user_command FOR oevents.
          SET HANDLER on_double_click FOR oevents.

          osalv->set_screen_status(
            report   = key-report
            pfstatus = 'STANDARD'
*           set_functions = cl_salv_model_base=>c_functions_none
          ).

          DATA(lv_title) = |{ TEXT-t01 } / { lines( it_alv ) } { TEXT-l02 }|.
          SET TITLEBAR '1000' WITH lv_title..
          osalv->display( ).
        ELSE.
          osalv->refresh(
            s_stable = ls_stable
          ).
        ENDIF.
      CATCH cx_salv_msg cx_salv_data_error cx_salv_not_found cx_fdt_excel_core INTO DATA(oerror).
        MESSAGE oerror TYPE 'I' RAISING ex_failed.
    ENDTRY.

  ENDMETHOD.

  METHOD on_user_command.
    CASE e_salv_function.
      WHEN 'TEST' OR 'EXEC'.
        DATA(gt_rows) = osalv->get_selections( )->get_selected_rows( ).
        IF gt_rows IS INITIAL.
          MESSAGE s104(dlcn) DISPLAY LIKE 'E'."Seleccione por lo menos un registro
          EXIT.
        ENDIF.

        IF e_salv_function = 'EXEC'.
          DATA(xtest) = ``.
          DATA(answer) = popup_to_confirm(
            title    = 'Confirmar'(t03)
            question = '¿Está seguro de ejecutar la carga de facturas?'(q01)
            btn1     = TEXT-bt1
            btn2     = TEXT-bt2
          ).

          IF answer NE '1'.
            RETURN.
          ENDIF.
        ELSE.
          xtest = abap_true.
        ENDIF.

        TYPES ty_collect LIKE LINE OF me->r_invoice_id.
        LOOP AT gt_rows ASSIGNING FIELD-SYMBOL(<frow>).
          READ TABLE it_alv ASSIGNING FIELD-SYMBOL(<fs_alv>) INDEX <frow>.
          IF sy-subrc EQ 0.
            COLLECT VALUE ty_collect( sign = 'I' option = 'EQ' low = <fs_alv>-invoice_id ) INTO me->r_invoice_id.
          ENDIF.
        ENDLOOP.

        create_invoices( iv_test = xtest ).
      WHEN 'MSG'.
        zcl_abap_util=>show_log( it_return ).
      WHEN 'REFRESH'.
        CLEAR: me->it_alv, me->it_return.
        show_alv( ).
    ENDCASE.
  ENDMETHOD.

  METHOD on_double_click.
    CHECK row IS NOT INITIAL.

    READ TABLE me->it_alv ASSIGNING FIELD-SYMBOL(<fs_alv>) INDEX row.
    CHECK sy-subrc EQ 0.

    CASE sender.
      WHEN me->osalv->get_event( ).
        CASE column.
          WHEN 'PO_NUMBER' OR 'PO_ITEM'.
            CHECK <fs_alv>-po_number IS NOT INITIAL.
            CALL FUNCTION 'ME_DISPLAY_PURCHASE_DOCUMENT'
              EXPORTING
                i_ebeln              = <fs_alv>-po_number
                i_ebelp              = <fs_alv>-po_item
              EXCEPTIONS
                not_found            = 1
                no_authority         = 2
                invalid_call         = 3
                preview_not_possible = 4
                OTHERS               = 5.
            IF sy-subrc <> 0.
              MESSAGE ID sy-msgid TYPE 'S' NUMBER sy-msgno
                        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
            ENDIF.

          WHEN 'INV_DOC_NO' OR 'FISC_YEAR'.
            CHECK <fs_alv>-inv_doc_no IS NOT INITIAL.

            SET PARAMETER ID 'RBN' FIELD <fs_alv>-inv_doc_no.
            SET PARAMETER ID 'GJR' FIELD <fs_alv>-fisc_year.
            CALL TRANSACTION 'MIR4' AND SKIP FIRST SCREEN.
        ENDCASE.
    ENDCASE.
  ENDMETHOD.

  METHOD create_invoices.
    DATA it_return     TYPE bapiret2_t.
    DATA ls_headerdata TYPE bapi_incinv_create_header.
    DATA it_itemdata   TYPE TABLE OF bapi_incinv_create_item.
    DATA: BEGIN OF ls_invoice,
            inv_doc_no TYPE re_belnr,
            fisc_year  TYPE gjahr,
          END OF ls_invoice.
    DATA ls_alv LIKE LINE OF it_alv.
    DATA lv_docitem TYPE rblgp.

    DATA lv_invoices TYPE sy-tabix.
    SELECT COUNT( DISTINCT invoice_id ) FROM @it_alv AS d INTO @lv_invoices ##ITAB_DB_SELECT.

    "Buscar información de referencia
    SELECT
    FROM @it_alv    AS a
    INNER JOIN ekpo AS p ON p~ebeln = a~po_number AND p~ebelp = a~po_item
    LEFT OUTER JOIN ekbe AS e ON e~ebeln = a~po_number AND e~ebelp = a~po_item
    FIELDS p~ebeln, p~ebelp, p~webre, p~meins, e~lfbnr, e~lfgja, e~lfpos
    WHERE p~webre = 'X' "VerFactEM
    AND   e~vgabe = '1' "Entrada de mercancía
    INTO TABLE @DATA(it_ekbe)
    .

    DATA lv_invoice TYPE i.
    DATA po_item_buffer   TYPE ebelp.
    DATA po_number_buffer TYPE bstnr.

    LOOP AT it_alv ASSIGNING FIELD-SYMBOL(<fs_alv>) WHERE invoice_id IN r_invoice_id.
      AT NEW invoice_id ##LOOP_AT_OK.
        lv_invoice += 1.
        cl_progress_indicator=>progress_indicate(
          i_text               = |{ TEXT-l04 } { lv_invoice }/{ lv_invoices }|
          i_processed          = lv_invoice
          i_total              = lv_invoices
          i_output_immediately = abap_true ).
        MOVE-CORRESPONDING <fs_alv> TO ls_headerdata.
      ENDAT.

      APPEND INITIAL LINE TO it_itemdata ASSIGNING FIELD-SYMBOL(<fs_itemdata>).
      MOVE-CORRESPONDING <fs_alv> TO <fs_itemdata>.
      IF <fs_itemdata>-invoice_doc_item IS INITIAL.
        lv_docitem += 1.
        <fs_itemdata>-invoice_doc_item = lv_docitem.
      ENDIF.

      "Buscar datos referencia (si EKPO-WEBRE = 'X')
      IF line_exists(   it_ekbe[ ebeln = <fs_alv>-po_number ebelp = <fs_alv>-po_item ] ).
        DATA(ls_ekbe) = it_ekbe[ ebeln = <fs_alv>-po_number ebelp = <fs_alv>-po_item ].
        <fs_itemdata>-ref_doc      = ls_ekbe-lfbnr.
        <fs_itemdata>-ref_doc_year = ls_ekbe-lfgja.
        <fs_itemdata>-ref_doc_it   = ls_ekbe-lfpos.
        IF <fs_itemdata>-po_unit IS INITIAL.
          <fs_itemdata>-po_unit = ls_ekbe-meins.
        ENDIF.
      ENDIF.

      AT END OF invoice_id ##LOOP_AT_OK.
        CALL FUNCTION 'BAPI_INCOMINGINVOICE_CREATE'
          EXPORTING
            headerdata       = ls_headerdata
*           ADDRESSDATA      =
          IMPORTING
            invoicedocnumber = ls_invoice-inv_doc_no
            fiscalyear       = ls_invoice-fisc_year
          TABLES
            itemdata         = it_itemdata
*           ACCOUNTINGDATA   =
*           GLACCOUNTDATA    =
*           MATERIALDATA     =
*           TAXDATA          =
*           WITHTAXDATA      =
*           VENDORITEMSPLITDATA       =
            return           = it_return
*           EXTENSIONIN      =
*           TM_ITEMDATA      =
*           NFMETALLITMS     =
*           ASSETDATA        =
          .

        IF  iv_test = abap_false
        AND ls_invoice IS NOT INITIAL.
          CALL FUNCTION 'BAPI_TRANSACTION_COMMIT'
            EXPORTING
              wait = abap_true.
        ENDIF.

        IF ls_invoice IS NOT INITIAL.
          ls_alv-icon       = icon_led_green.
          ls_alv-inv_doc_no = ls_invoice-inv_doc_no.
          ls_alv-fisc_year  = ls_invoice-fisc_year.
          LOOP AT it_return ASSIGNING FIELD-SYMBOL(<fs_return>) WHERE type = 'S'.
            MESSAGE ID <fs_return>-id TYPE <fs_return>-type NUMBER <fs_return>-number
            WITH <fs_return>-message_v1 <fs_return>-message_v2 <fs_return>-message_v3 INTO ls_alv-msg.
            EXIT.
          ENDLOOP.
        ELSE.
          ls_alv-icon     = icon_led_red.
          CLEAR: ls_alv-inv_doc_no, ls_alv-fisc_year.
          LOOP AT it_return ASSIGNING <fs_return> WHERE type CA 'EA'.
            MESSAGE ID <fs_return>-id TYPE <fs_return>-type NUMBER <fs_return>-number
            WITH <fs_return>-message_v1 <fs_return>-message_v2 <fs_return>-message_v3 INTO ls_alv-msg.
            EXIT.
          ENDLOOP.
        ENDIF.

        IF ls_invoice IS NOT INITIAL AND it_return IS INITIAL.
          "Se ha creado doc.Nº & &
          MESSAGE s060(m8) WITH ls_invoice-inv_doc_no ls_invoice-fisc_year INTO ls_alv-msg ##MG_MISSING..
          APPEND INITIAL LINE TO it_return ASSIGNING <fs_return>.
          <fs_return>-id         = sy-msgid.
          <fs_return>-type       = sy-msgty.
          <fs_return>-number     = sy-msgno.
          <fs_return>-message    = ls_alv-msg.
          <fs_return>-message_v1 = sy-msgv1.
          <fs_return>-message_v2 = sy-msgv2.
          <fs_return>-message_v3 = sy-msgv3.
          <fs_return>-message_v4 = sy-msgv4.
        ENDIF.

        MODIFY it_alv FROM ls_alv TRANSPORTING icon inv_doc_no fisc_year msg WHERE invoice_id = <fs_alv>-invoice_id.

        DELETE ADJACENT DUPLICATES FROM it_return COMPARING type id number message.
        APPEND LINES OF it_return TO me->it_return.
        CLEAR: ls_headerdata, it_itemdata, ls_invoice, lv_docitem.
      ENDAT.
    ENDLOOP.
    CLEAR: me->r_invoice_id.

*    SORT me->it_return BY type id number message.
    DELETE ADJACENT DUPLICATES FROM me->it_return COMPARING type id number message.
    me->osalv->refresh(
      s_stable = ls_stable
*     refresh_mode = if_salv_c_refresh=>soft
    ).
  ENDMETHOD.

  METHOD popup_to_confirm.
    CALL FUNCTION 'POPUP_TO_CONFIRM'
      EXPORTING
        titlebar      = title
        text_question = question
        text_button_1 = btn1
        text_button_2 = btn2
      IMPORTING
        answer        = answer.
  ENDMETHOD.
ENDCLASS.

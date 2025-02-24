*&---------------------------------------------------------------------*
*& Include          ZPR_CARGA_MIRO_FACTURAS_F02
*&---------------------------------------------------------------------*

FORM fill_data.

  IF s_ebeln IS NOT INITIAL AND p_bukrs IS NOT INITIAL.
    SELECT * FROM ekko INTO TABLE @DATA(lt_ekko)
      WHERE ebeln IN @s_ebeln
        AND bukrs EQ @p_bukrs.

    IF sy-subrc EQ 0.
      SELECT * FROM ekpo INTO TABLE @DATA(lt_ekpo)
        FOR ALL ENTRIES IN @lt_ekko
        WHERE ebeln EQ @lt_ekko-ebeln.

    ENDIF.

    PERFORM fill_header.

    LOOP AT lt_ekpo INTO DATA(ls_ekpo).

      READ TABLE lt_ekko INTO DATA(ls_ekko) WITH KEY ebeln = ls_ekpo-ebeln.
      IF sy-subrc EQ 0.
        ls_excel-invoice_id     = '10'.
        ls_excel-invoice_ind    = 'X'.
        ls_excel-comp_code      = ls_ekko-bukrs.
        ls_excel-doc_type       = 'RE'.
        ls_excel-ref_doc_no     = ''.
        ls_excel-doc_date       = |{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum(4) }|.
        ls_excel-pstng_date     = |{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum(4) }|.
        ls_excel-header_txt     = ''.
        ls_excel-currency       = ls_ekko-waers.
        ls_excel-gross_amount   = ''.
        ls_excel-calc_tax_ind   = ''.
        ls_excel-bline_date     = ''.
        ls_excel-netterms       = ''.
        ls_excel-fixedterms     = ls_ekko-zterm.
        ls_excel-del_costs      = ''.
        ls_excel-alloc_nmbr     = ''.
        ls_excel-item_text      = ''.
        ls_excel-inv_rec_date   = |{ sy-datum+6(2) }.{ sy-datum+4(2) }.{ sy-datum(4) }|.
      ENDIF.

      ls_excel-del_costs_taxc = ls_ekpo-mwskz.
      ls_excel-po_item        = ls_ekpo-ebelp.
      ls_excel-material       = ls_ekpo-matnr.
      ls_excel-quantity       = ls_ekpo-menge.
      ls_excel-po_unit        = ls_ekpo-meins.
      ls_excel-item_amount    = ls_ekpo-netpr.
      ls_excel-po_number      = ls_ekpo-ebeln.
      ls_excel-tax_code       = ''.

      APPEND ls_excel TO lt_excel.
      CLEAR: ls_excel, ls_ekko, ls_ekpo.
    ENDLOOP.

    IF lt_excel[] IS NOT INITIAL.
      PERFORM convert_xls.

    ELSE.
      MESSAGE 'No se encontraron datos para la selección' TYPE 'S' DISPLAY LIKE 'E'.
      STOP.
    ENDIF.

  ELSE.
    MESSAGE 'Complete todos los campos obligatorios' TYPE 'S' DISPLAY LIKE 'E'.
    STOP.

  ENDIF.

ENDFORM.

*&---------------------------------------------------------------------*
*& Form convert_xls
*&---------------------------------------------------------------------*
FORM convert_xls.

  DATA: lv_action   TYPE i,
        lv_filename TYPE string,
        lv_fullpath TYPE string,
        lv_path     TYPE string.

  DATA: lt_columns TYPE if_fdt_doc_spreadsheet=>t_column.
  DATA: ls_header TYPE ty_excel.
*  DATA: it_excel TYPE TABLE OF ty_header.


  TRY.
      DATA(o_desc) = CAST cl_abap_structdescr( cl_abap_structdescr=>describe_by_data( ls_header ) ).


      LOOP AT o_desc->get_components( ) ASSIGNING FIELD-SYMBOL(<c>).
        IF <c> IS ASSIGNED.
          IF <c>-type->kind = cl_abap_structdescr=>kind_elem.
            APPEND VALUE #( id           = sy-tabix
                            name         = <c>-name
                            display_name = <c>-name
                            is_result    = abap_true
                            type         = <c>-type ) TO lt_columns.
          ENDIF.
        ENDIF.
      ENDLOOP.


      LOOP AT lt_columns ASSIGNING FIELD-SYMBOL(<fs_columns>).
        CASE <fs_columns>-name.
          WHEN 'INVOICE_ID'.
            <fs_columns>-display_name = 'Datos cab.'.
          WHEN 'INVOICE_IND'.
            <fs_columns>-display_name = ` `.
          WHEN 'COMP_CODE'.
            <fs_columns>-display_name = ` `.
          WHEN 'DOC_TYPE'.
            <fs_columns>-display_name = ` `.
          WHEN 'REF_DOC_NO'.
            <fs_columns>-display_name = ` `.
          WHEN 'DOC_DATE'.
            <fs_columns>-display_name = ` `.
          WHEN 'PSTNG_DATE'.
            <fs_columns>-display_name = ` `.
          WHEN 'HEADER_TXT'.
            <fs_columns>-display_name = ` `.
          WHEN 'CURRENCY'.
            <fs_columns>-display_name = ` `.
          WHEN 'GROSS_AMOUNT'.
            <fs_columns>-display_name = ` `.
          WHEN 'CALC_TAX_IND'.
            <fs_columns>-display_name = ` `.
          WHEN 'BLINE_DATE'.
            <fs_columns>-display_name = ` `.
          WHEN 'NETTERMS'.
            <fs_columns>-display_name = ` `.
          WHEN 'FIXEDTERMS'.
            <fs_columns>-display_name = ` `.
          WHEN 'DEL_COSTS'.
            <fs_columns>-display_name = ` `.
          WHEN 'DEL_COSTS_TAXC'.
            <fs_columns>-display_name = ` `.
          WHEN 'ALLOC_NMBR'.
            <fs_columns>-display_name = ` `.
          WHEN 'ITEM_TEXT'.
            <fs_columns>-display_name = ` `.
          WHEN 'INV_REC_DATE'.
            <fs_columns>-display_name = ` `.
          WHEN 'PO_ITEM '.
            <fs_columns>-display_name = 'Posicion'.
          WHEN 'MATERIAL'.
            <fs_columns>-display_name = ` `.
          WHEN 'QUANTITY'.
            <fs_columns>-display_name = ` `.
          WHEN 'PO_UNIT'.
            <fs_columns>-display_name = ` `.
          WHEN 'ITEM_AMOUNT'.
            <fs_columns>-display_name = ` `.
          WHEN 'PO_NUMBER'.
            <fs_columns>-display_name = ` `.
          WHEN 'TAX_CODE'.
            <fs_columns>-display_name = ` `.
        ENDCASE.
      ENDLOOP.

      DATA(lv_bin_data) = cl_fdt_xl_spreadsheet=>if_fdt_doc_spreadsheet~create_document( columns      = lt_columns
                                                                                         itab         = REF #( lt_excel )
                                                                                         iv_call_type = ' ' ).

      IF xstrlen( lv_bin_data ) > 0.

        cl_gui_frontend_services=>file_save_dialog( EXPORTING default_file_name = 'Plantilla descarga masiva facturas.xlsx'
                                                              default_extension = '.xlsx'
                                                              file_filter       = |xlsx (*.xlsx)\|*.xlsx\|{ cl_gui_frontend_services=>filetype_all }|
                                                    CHANGING  filename          = lv_filename
                                                              path              = lv_path
                                                              fullpath          = lv_fullpath
                                                              user_action       = lv_action ).


        " Convert xstring->solix (raw)
        IF lv_action EQ cl_gui_frontend_services=>action_ok.

          DATA(it_raw_data) = cl_bcs_convert=>xstring_to_solix( EXPORTING iv_xstring = lv_bin_data ).

          "GUI Download
          cl_gui_frontend_services=>gui_download( EXPORTING filename     = lv_fullpath
                                                            filetype     = 'BIN'
                                                            bin_filesize = xstrlen( lv_bin_data )
                                                  CHANGING  data_tab     = it_raw_data ).


        ENDIF.
      ENDIF.

    CATCH cx_root INTO DATA(e_text).

      MESSAGE e_text->get_text( ) TYPE 'I'.

  ENDTRY.



ENDFORM.
*&---------------------------------------------------------------------*
*& Form fill_header
*&---------------------------------------------------------------------*
FORM fill_header.
* Rellenado de cabecera para igualar plantilla modelo

*  APPEND VALUE #( invoice_id     = 'Datos cab.'
*                  po_item        = 'Posicion' )
*                  TO lt_excel.

  APPEND VALUE #( invoice_id     = 'INVOICE_ID'
                  invoice_ind    = 'INVOICE_IND'
                  comp_code      = 'COMP_CODE'
                  doc_type       = 'DOC_TYPE'
                  ref_doc_no     = 'REF_DOC_NO'
                  doc_date       = 'DOC_DATE'
                  pstng_date     = 'PSTNG_DATE'
                  header_txt     = 'HEADER_TXT'
                  currency       = 'CURRENCY'
                  gross_amount   = 'GROSS_AMOUNT'
                  calc_tax_ind   = 'CALC_TAX_IND'
                  bline_date     = 'BLINE_DATE'
                  netterms       = 'NETTERMS'
                  fixedterms     = 'FIXEDTERMS'
                  del_costs      = 'DEL_COSTS'
                  del_costs_taxc = 'DEL_COSTS_TAXC'
                  alloc_nmbr     = 'ALLOC_NMBR'
                  item_text      = 'ITEM_TEXT'
                  inv_rec_date   = 'INV_REC_DATE'
                  po_item        = 'PO_ITEM'
                  material       = 'MATERIAL'
                  quantity       = 'QUANTITY'
                  po_unit        = 'PO_UNIT'
                  item_amount    = 'ITEM_AMOUNT'
                  po_number      = 'PO NUMBER'
                  tax_code       = 'TAX_CODE' )
                  TO lt_excel.

  APPEND VALUE #( invoice_id     = ''
                  invoice_ind    = ''
                  comp_code      = 'COMPANYCODE'
                  doc_type       = 'TIPO DE DOCUMENTO'
                  ref_doc_no     = 'SUPPLIERINVOICEIDBYINVCGPARTY'
                  doc_date       = 'DOCUMENTDATE'
                  pstng_date     = 'POSTINGDATE'
                  header_txt     = 'ACCOUNTINGDOCUMENTHEADERTEXT'
                  currency       = 'DOCUMENTCURRENCY'
                  gross_amount   = 'INVOICEGROSSAMOUNT'
                  calc_tax_ind   = ''
                  bline_date     = 'DUECALCULATIONBASEDATE'
                  netterms       = 'NETPAYMENTDAYS'
                  fixedterms     = 'FIXEDCASHDISCOUNT'
                  del_costs      = 'UNPLANNEDDELIVERYCOST'
                  del_costs_taxc = 'UNPLANNEDDELIVERYCOSTTAXCODE'
                  alloc_nmbr     = 'ASSIGNMENTREFERENCE'
                  item_text      = 'SUPPLIERPOSTINGLINEITEMTEXT'
                  inv_rec_date   = 'INVOICERECEIPTDATE'
                  po_item        = 'ITEM'
                  material       = 'CODIGO MATERIAL'
                  quantity       = 'CANTIDAD'
                  po_unit        = 'UNIDAD MEDIDA'
                  item_amount    = 'IMPORTE'
                  po_number      = 'DOC COMPRAS'
                  tax_code       = '' )
                  TO lt_excel.

  APPEND VALUE #( invoice_id     = '*ID de factura'
                  invoice_ind    = 'Indicador: Contabilizar factura'
                  comp_code      = '*Sociedad (4)'
                  doc_type       = 'RE: FACTURA'
                  ref_doc_no     = 'Referencia (16)'
                  doc_date       = '*Fecha de documento'
                  pstng_date     = '*Fecha de contabilización'
                  header_txt     = 'Texto de cabecera de documento (25)'
                  currency       = '*Moneda (5)'
                  gross_amount   = '*Importe bruto de factura en moneda del documento'
                  calc_tax_ind   = '¿Calcular impuesto automáticamente?'
                  bline_date     = 'Fecha base para cálculo del vencimiento'
                  netterms       = 'Plazo para condición de pago neto (3)'
                  fixedterms     = 'Condición de pago fija (1)'
                  del_costs      = 'Costes indirectos de adquisición no planificados'
                  del_costs_taxc = 'Indicador de IVA (2)'
                  alloc_nmbr     = 'Número de asignación (18)'
                  item_text      = 'Texto posición (50)'
                  inv_rec_date   = 'Fecha de recepción de factura'
                  po_item        = 'Posicion'
                  material       = 'CODIGO MATERIAL'
                  quantity       = 'CANTIDAD'
                  po_unit        = 'UNIDAD MEDIDA'
                  item_amount    = 'IMPORTE'
                  po_number      = 'DOC COMPRAS'
                  tax_code       = 'IMPUESTO' )
                  TO lt_excel.

*      LOOP AT lt_columns ASSIGNING FIELD-SYMBOL(<fs_columns>).
*        CASE <fs_columns>-name.
*          WHEN 'INVOICE_ID'.
*            <fs_columns>-display_name = '*ID de factura'.
*          WHEN 'INVOICE_IND'.
*            <fs_columns>-display_name = 'Indicador: Contabilizar factura'.
*          WHEN 'COMP_CODE'.
*            <fs_columns>-display_name = '*Sociedad (4)'.
*          WHEN 'DOC_TYPE'.
*            <fs_columns>-display_name = 'RE: FACTURA'.
*          WHEN 'REF_DOC_NO'.
*            <fs_columns>-display_name = 'Referencia (16)'.
*          WHEN 'DOC_DATE'.
*            <fs_columns>-display_name = '*Fecha de documento'.
*          WHEN 'PSTNG_DATE'.
*            <fs_columns>-display_name = '*Fecha de contabilización'.
*          WHEN 'HEADER_TXT'.
*            <fs_columns>-display_name = 'Texto de cabecera de documento (25)'.
*          WHEN 'CURRENCY'.
*            <fs_columns>-display_name = '*Moneda (5)'.
*          WHEN 'GROSS_AMOUNT'.
*            <fs_columns>-display_name = '*Importe bruto de factura en moneda del documento'.
*          WHEN 'CALC_TAX_IND'.
*            <fs_columns>-display_name = '¿Calcular impuesto automáticamente?'.
*          WHEN 'BLINE_DATE'.
*            <fs_columns>-display_name = 'Fecha base para cálculo del vencimiento'.
*          WHEN 'NETTERMS'.
*            <fs_columns>-display_name = 'Plazo para condición de pago neto (3)'.
*          WHEN 'FIXEDTERMS'.
*            <fs_columns>-display_name = 'Condición de pago fija (1)'.
*          WHEN 'DEL_COSTS'.
*            <fs_columns>-display_name = 'Costes indirectos de adquisición no planificados'.
*          WHEN 'ALLOC_NMBR'.
*            <fs_columns>-display_name = 'Número de asignación (18)'.
*          WHEN 'ITEM_TEXT'.
*            <fs_columns>-display_name = 'Texto posición (50)'.
*          WHEN 'INV_REC_DATE'.
*            <fs_columns>-display_name = 'Fecha de recepción de factura'.
*          WHEN 'PO_ITEM '.
*            <fs_columns>-display_name = 'Posicion'.
*          WHEN 'MATERIAL'.
*            <fs_columns>-display_name = 'CODIGO MATERIAL'.
*          WHEN 'QUANTITY'.
*            <fs_columns>-display_name = 'CANTIDAD'.
*          WHEN 'PO_UNIT'.
*            <fs_columns>-display_name = 'UNIDAD MEDIDA'.
*          WHEN 'ITEM_AMOUNT'.
*            <fs_columns>-display_name = 'IMPORTE'.
*          WHEN 'PO NUMBER'.
*            <fs_columns>-display_name = 'DOC COMPRAS'.
*          WHEN 'TAX_CODE'.
*            <fs_columns>-display_name = 'IMPUESTO'.
*        ENDCASE.
*      ENDLOOP.

ENDFORM.

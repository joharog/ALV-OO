*&---------------------------------------------------------------------*
*& Include          ZPR_CARGA_MIRO_FACTURAS_TOP
*&---------------------------------------------------------------------*
TABLES sscrfields ##NEEDED.
TABLES ekko.

TYPES: BEGIN OF ty_excel,
         invoice_id     TYPE string, "shared_xx_invoice_nr,
         invoice_ind    TYPE string, "xrech,
         comp_code      TYPE string, "bukrs,
         doc_type       TYPE string, "blart,
         ref_doc_no     TYPE string, "xblnr,
         doc_date       TYPE string, "bldat,
         pstng_date     TYPE string, "budat,
         header_txt     TYPE string, "bktxt,
         currency       TYPE string, "waers,
         gross_amount   TYPE string, "bapi_rmwwr,
         calc_tax_ind   TYPE string, "xmwst,
         bline_date     TYPE string, "dzfbdt,
         netterms       TYPE string, "dzbd3t,
         fixedterms     TYPE string, "dzbfix,
         del_costs      TYPE string, "bapi_beznk,
         del_costs_taxc TYPE string, "mwskz_bnk,
         alloc_nmbr     TYPE string, "dzuonr,
         item_text      TYPE string, "sgtxt,
         inv_rec_date   TYPE string, "reindat,

         po_item        TYPE string, "ebelp,
         material       TYPE string, "matnr18,
         quantity       TYPE string, "menge_d,
         po_unit        TYPE string, "bstme,
         item_amount    TYPE string, "bapiwrbtr,
         po_number      TYPE string, "bstnr,
         tax_code       TYPE string, "mwskz_mrm,
       END OF ty_excel.

DATA: lt_excel TYPE TABLE OF ty_excel,
      ls_excel TYPE ty_excel.

DATA: dir TYPE string.

CONSTANTS c_mime_obj TYPE string VALUE '/SAP/PUBLIC/Plantillla carga masiva facturas.xlsx'.
CONSTANTS c_from TYPE i VALUE 5.

*-----------------------------------------------------------
* Clases
*-----------------------------------------------------------
CLASS lcl_alv DEFINITION.
  PUBLIC SECTION.
    TYPES: BEGIN OF ty_alv,
             invoice_id     TYPE shared_xx_invoice_nr,
             invoice_ind    TYPE xrech,
             comp_code      TYPE bukrs,
             doc_type       TYPE blart,
             ref_doc_no     TYPE xblnr,
             doc_date       TYPE bldat,
             pstng_date     TYPE budat,
             header_txt     TYPE bktxt,
             currency       TYPE waers,
             gross_amount   TYPE bapi_rmwwr,
             calc_tax_ind   TYPE xmwst,
             bline_date     TYPE dzfbdt,
             netterms       TYPE dzbd3t,
             fixedterms     TYPE dzbfix,
             del_costs      TYPE bapi_beznk,
             del_costs_taxc TYPE mwskz_bnk,
             alloc_nmbr     TYPE dzuonr,
             item_text      TYPE sgtxt,
             inv_rec_date   TYPE reindat,

             po_item        TYPE ebelp,
             material       TYPE matnr18,
             quantity       TYPE menge_d,
             po_unit        TYPE bstme,
             item_amount    TYPE bapiwrbtr,
             po_number      TYPE bstnr,
             tax_code	      TYPE mwskz_mrm,

             inv_doc_no     TYPE re_belnr,
             fisc_year      TYPE gjahr,
             icon           TYPE /sapapo/ts_lock_icon,
             msg            TYPE fin_message_alv,
           END OF ty_alv,
           tt_alv TYPE TABLE OF ty_alv WITH EMPTY KEY.

    METHODS get_excel_data IMPORTING iv_file       TYPE string.

    METHODS show_alv
      EXCEPTIONS
        ex_failed.
    METHODS create_invoices IMPORTING iv_test TYPE string.
    METHODS popup_to_confirm IMPORTING title         TYPE any
                                       question      TYPE any
                                       btn1          TYPE any
                                       btn2          TYPE any
                             RETURNING VALUE(answer) TYPE char1.
    METHODS on_user_command FOR EVENT added_function OF cl_salv_events
      IMPORTING e_salv_function.
    METHODS on_double_click FOR EVENT double_click OF cl_salv_events_table
      IMPORTING row column sender ##NEEDED.

  PRIVATE SECTION.
    DATA it_worksheets TYPE zcl_abap_util=>tt_worksheets.
    DATA osalv         TYPE REF TO cl_salv_table.
    DATA it_alv        TYPE tt_alv.
    DATA it_aux        TYPE tt_alv.
    DATA it_return     TYPE bapiret2_t.
    DATA ls_stable     TYPE lvc_s_stbl VALUE 'XX'.
    DATA r_invoice_id  TYPE RANGE OF shared_xx_invoice_nr.
ENDCLASS.

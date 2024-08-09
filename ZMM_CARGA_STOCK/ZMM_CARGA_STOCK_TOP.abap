*&---------------------------------------------------------------------*
*&  Include           ZMM_CARGA_STOCK_TOP
*&---------------------------------------------------------------------*

TYPE-POOLS: slis.
TYPE-POOLS: icon.

*----------------------------------------------------------------------*
* Definición de Tipos
*----------------------------------------------------------------------*
TYPES:
BEGIN OF ty_carga,

*** Info
  select TYPE char1,
  status TYPE char4,
  log    TYPE char255,

*** Nivel de Cabecera | GOODSMVT_HEADER
  pstng_date     TYPE     budat,         "Fecha de contabilización en el documento
  doc_date       TYPE     bldat,         "Fecha de documento en documento
  header_txt     TYPE     bktxt,         "Texto de cabecera de documento

*** Nivel de Item | GOODSMVT_ITEM
  material       TYPE     matnr,         "Número de material
  plant	         TYPE     werks_d,       "Centro
  stge_loc       TYPE     lgort_d,       "Almacén
  move_type	     TYPE     bwart,         "Clase de movimiento
  val_type       TYPE     bwtar_d,       "Clase de valoración
  batch	         TYPE     charg_d,       "Número de lote
  entry_qnt      TYPE     erfmg,         "Cantidad en unidad de medida de entrada
  entry_uom      TYPE     erfme,         "Unidad de medida de entrada
  amount_lc      TYPE     bapi_exbwr,    "Importe de contab.introducido externamente en moneda local
  stck_type      TYPE     mb_insmk,      "Tipo stock
  spec_stock     TYPE     sobkz,         "Indicador de stock especial
  vendor         TYPE     elifn,         "Número de cuenta del proveedor
  customer       TYPE     ekunn,         "Número de cuenta del cliente
  sales_ord	     TYPE     kdauf,         "Número del pedido de cliente

  field_style    TYPE    lvc_t_styl,     "FOR DISABLE
  waers          TYPE    waers,          "Moneda
  vprsv          TYPE    vprsv,          "Indicador de control de precios
  mlast          TYPE    ck_ml_abst,     "Liquidación de ledger de materiales: Control
END OF ty_carga.

*----------------------------------------------------------------------*
*               D E F I N I C I O N   C L A S E S
*----------------------------------------------------------------------*

CLASS: cls_alv_oo DEFINITION DEFERRED,
       cls_eventos DEFINITION DEFERRED.

DATA: obj_alv_oo  TYPE REF TO cls_alv_oo,
      obj_eventos TYPE REF TO cls_eventos.

*----------------------------------------------------------------------*
* Definición Variables Globales
*----------------------------------------------------------------------*
DATA: it_fcat      TYPE STANDARD TABLE OF lvc_s_fcat,
      wa_fcat      TYPE lvc_s_fcat,
      wa_layout    TYPE lvc_s_layo,

      it_excluding TYPE STANDARD TABLE OF ui_func,
      wa_exclude   TYPE ui_func,

      vg_container TYPE REF TO cl_gui_custom_container,
      obj_alv_grid TYPE REF TO cl_gui_alv_grid.

DATA:
      gv_answer TYPE char1,
      ok_code TYPE sy-ucomm,
      gi_rc        TYPE i,
      gs_title     TYPE string,
      p_file       TYPE rlgrap-filename.

DATA:
      gt_excel TYPE TABLE OF alsmex_tabline,
      gs_excel TYPE alsmex_tabline,
      gt_data  TYPE TABLE OF ty_carga,
      gs_data  TYPE ty_carga.


*----------------------------------------------------------------------*
* Definición Tablas Internas Globales
*----------------------------------------------------------------------*
DATA:
      gti_file_table TYPE filetable,
      gti_carga      TYPE STANDARD TABLE OF ty_carga.


*----------------------------------------------------------------------*
*                 F I E L D   -   S Y M B O L S
*----------------------------------------------------------------------*
FIELD-SYMBOLS: <gfs_data>      TYPE ty_carga.

*----------------------------------------------------------------------*
*                 C O N S T A N T S
*----------------------------------------------------------------------*
DATA:
      gc_red   VALUE icon_red_light TYPE char4,
      gc_green VALUE icon_green_light TYPE char4.


*-------------------------------------------------------------------
*           S T A R T  -  O F  -  S E L E C T I O N
*---------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.
PARAMETERS: pfile TYPE string OBLIGATORY, "DEFAULT 'C:\Users\Ung\Desktop\NUS Consulting\ALICORP\MM-Carga Inicial Stock\Layout Carga Stock.xlsx',
            pgmcode TYPE gm_code OBLIGATORY. "DEFAULT '03.
SELECTION-SCREEN END OF BLOCK b01.

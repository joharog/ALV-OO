*&---------------------------------------------------------------------*
*&  Include           ZMM_CARGA_PED_COMPRA_TOP
*&---------------------------------------------------------------------*

TYPE-POOLS: slis.
TYPE-POOLS: icon.

*----------------------------------------------------------------------*
* Definición de Tipos
*----------------------------------------------------------------------*
TYPES:
      BEGIN OF ty_carga,

*     Info/Interno
      ex_item          TYPE    char1,
      ex_serv          TYPE    char1,
      ex_impt          TYPE    char1,
      select           TYPE    char1,
      status           TYPE    char4,
      log              TYPE    char255,

*     Nivel de Cabecera | POHEADER
      doc_type         TYPE    esart,       "1 Clase de documento de compras
      comp_code        TYPE    bukrs,                       "2 Sociedad
      purch_org        TYPE    ekorg,       "3 Organización de compras
      pur_group        TYPE    bkgrp,       "4 Grupo de compras
      vendor           TYPE    elifn,       "5 Número de cuenta del proveedor
      doc_date         TYPE    ebdat,       "6 Fecha del documento de compras
      pmnttrms         TYPE    dzterm,      "7 Clave de condiciones de pago
      currency         TYPE    waers,       "8 Clave de moneda
      exch_rate        TYPE    wkurs,       "9 Tipo de cambio de moneda
      ex_rate_fx       TYPE    kufix,       "10 Indicador: Fijación del tipo de cambio
      incoterms1       TYPE    inco1,       "11 Incoterms parte 1
      temp1            TYPE    char20,      "12 Texto Cabecera
      temp2            TYPE    char20,      "13 Funciones de Interlocutor
      retention_type   TYPE    rettp,       "14 Indicador de retención
*     REF_1           TYPE    IHREZ,   "Referencia

*     Nivel de Items | POITEM
      acctasscat       TYPE    knttp,       "15 Tipo de imputación
      item_cat         TYPE    pstyp,       "16 Tipo de posición del documento de compras
      po_item          TYPE    ebelp,       "17 Número de posición del documento de compras
      matl_group       TYPE    matkl,       "18 Grupo de artículos
      material         TYPE    matnr,       "19 Número de material
      short_text       TYPE    txz01,       "20 Texto breve
      itm_quantity     TYPE    bstmg,       "21 Cantidad de pedido
      po_unit          TYPE    bstme,       "22 Unidad de medida de pedido
      net_price        TYPE    bapicurext,  "23 Importe de moneda para BAPIs (con 9 decimales)
      plant            TYPE    ewerk,                       "24 Centro
      stge_loc         TYPE    lgort_d,                     "25 Almacén
      preq_name        TYPE    afnam,       "26 Nombre del solicitante
      qual_insp        TYPE    insmk,       "27 Tipo de stock
      tax_code         TYPE    mwskz,       "28 Indicador IVA
      temp3            TYPE    char20,      "29 Clase de Condición
      temp4            TYPE    char20,      "30 Valor Clase de Condición
      conf_ctrl        TYPE    bstae,       "31 Clave de control de confirmaciones

*     Nivel de entregas | POSCHEDULE
      delivery_date   TYPE     eeind,       "32 Fecha de entrega

*     Nivel de Servicios | POSERVICES
      ext_line        TYPE     extrow,      "33 Número de línea
      service         TYPE     asnum,       "34 Número de servicio
      srv_quantity    TYPE     mengev,      "35 Cantidad
      base_uom        TYPE     meins,                       "36 UM base
      gr_price        TYPE     bapigrprice, "37 Precio bruto

*     Nivel de Imputacion | POACCOUNT
      serial_no       TYPE     dzekkn,      "38 Imputación actual
      distr_perc      TYPE     vproz,       "39 Porcentaje de distribución en la imputación múltiple
      part_inv        TYPE     twrkz,       "40 Fact. Parcial
      imp_quantity    TYPE     menge_d,     "41 Cantidad
      costcenter      TYPE     kostl,       "42 Centro de coste
      gl_account      TYPE     saknr,       "43 Número de la cuenta de mayor
      orderid         TYPE     aufnr,       "44 Número de orden

      field_style     TYPE    lvc_t_styl,   "Habilitar/Deshabilitar Semaforo

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


*----------------------------------------------------------------------*
*                 B A P I - D E C L A R A T I O N S
*----------------------------------------------------------------------*

TYPES: BEGIN OF ty_poitem.
        INCLUDE STRUCTURE bapimepoitem.
TYPES: END OF ty_poitem.

TYPES: BEGIN OF ty_poitemx.
        INCLUDE STRUCTURE bapimepoitemx.
TYPES: END OF ty_poitemx.

TYPES: BEGIN OF ty_poaccount.
        INCLUDE STRUCTURE bapimepoaccount.
TYPES: END OF ty_poaccount.

TYPES: BEGIN OF ty_poaccountx.
        INCLUDE STRUCTURE bapimepoaccountx.
TYPES: END OF ty_poaccountx.

DATA:
      t_poheader     LIKE bapimepoheader,
      t_poheaderx    LIKE bapimepoheaderx,

      t_poitem       TYPE TABLE OF ty_poitem,
      w_poitem       LIKE LINE OF t_poitem,
      t_poitemx      TYPE TABLE OF ty_poitemx,
      w_poitemx      LIKE LINE OF t_poitemx,

      t_poschedule   TYPE TABLE OF bapimeposchedule,
      w_poschedule   LIKE LINE OF t_poschedule,
      t_poschedulex  TYPE TABLE OF bapimeposchedulx,
      w_poschedulex  LIKE LINE OF t_poschedulex,

      t_poaccount    TYPE TABLE OF ty_poaccount,
      w_poaccount    LIKE LINE OF t_poaccount,
      t_poaccountx   TYPE TABLE OF ty_poaccountx,
      w_poaccountx   LIKE LINE OF t_poaccountx,

      t_poservices   TYPE TABLE OF bapiesllc,
      w_poservices   LIKE LINE OF t_poservices,

      t_posrvaccessvalues TYPE TABLE OF bapiesklc,
      w_posrvaccessvalues LIKE LINE OF t_posrvaccessvalues,


      t_return_bapi   TYPE TABLE OF bapiret2,
      w_return_bapi   TYPE bapiret2,
      t_return_commit TYPE TABLE OF bapiret2,
      w_return_commit TYPE bapiret2.


DATA:
      lv_tabix TYPE sy-tabix,
      tabix_in TYPE sy-tabix,
      lv_pos TYPE ebelp,
      lv_srv TYPE extrow,
      lv_imp TYPE dzekkn,
      flag_p TYPE char1,
      flag_s TYPE char1,
      flag_i TYPE char1.


DATA:
      lt_serv TYPE TABLE OF ty_carga,
      lt_impt TYPE TABLE OF ty_carga.

FIELD-SYMBOLS: <fs_data> TYPE ty_carga,
               <fs_serv> TYPE ty_carga,
               <fs_impt> TYPE ty_carga.

RANGES: r_srv FOR ekko-bsart.

r_srv-sign = 'E'.
r_srv-option = 'EQ'.
r_srv-low = 'PSER'.
APPEND r_srv TO r_srv.

r_srv-sign = 'E'.
r_srv-option = 'EQ'.
r_srv-low = 'SV'.
APPEND r_srv TO r_srv.

*-------------------------------------------------------------------
*           S T A R T  -  O F  -  S E L E C T I O N
*---------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE text-001.
PARAMETERS: pfile TYPE string OBLIGATORY.
SELECTION-SCREEN END OF BLOCK b01.

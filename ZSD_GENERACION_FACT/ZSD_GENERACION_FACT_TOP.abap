*&---------------------------------------------------------------------*
*& Include          ZSD_GENERACION_NC_TOP
*&---------------------------------------------------------------------*

TYPE-POOLS: slis.
TYPE-POOLS: icon.
TABLES: vbrk.

*----------------------------------------------------------------------*
*  T Y P E S  -  D E F I N I T I O N
*----------------------------------------------------------------------*
TYPES: BEGIN OF ty_alv,
         check      TYPE char1,           "Checkbox
         vbeln_pv   TYPE vbak-vbeln,      "Num.Pedido de Ventas
         auart      TYPE vbak-auart,      "Clase Pedido de Ventas
         d_auart    TYPE tvakt-bezei,     "Denom. Clase Pedido de Ventas
         vkorg      TYPE vbak-vkorg,      "Organización de Ventas
         d_vkorg    TYPE tvkot-vtext,     "Denominacion Org.Vtas
         vtweg      TYPE vbak-vtweg,      "Canal de Distribución
         d_vtweg    TYPE tvtwt-vtext,     "Denominacion CDist.
         spart      TYPE vbak-spart,      "Sector
         d_spart    TYPE tspat-vtext,     "Denominacion Sect.
         vkbur      TYPE vbak-vkbur,      "Oficina de Ventas
         d_vkbur    TYPE tvkbt-bezei,     "Denom. Ofic.Vtas
         bstkd      TYPE vbkd-bstkd,      "Referencia de Cliente
         kunnr      TYPE vbak-kunnr,      "Cliente
         name1      TYPE name1_gp,        "Nombre Cliente

         itm_number TYPE posnr_va,        "Posicion
         matnr      TYPE matnr18,         "Codigo de Material
         maktx      TYPE makt-maktx,      "Denom.Material
         target_qty TYPE dzmeng,          "Cantidad
         target_qu  TYPE dzieme,          "Unidad de Medida
         batch      TYPE charg_d,         "Lote
         plant      TYPE werks_d,         "Centro
         ship_point TYPE likp-vstel,      "Puesto de Expedición
         d_vstel    TYPE tvstt-vtext,     "Denom.Puesto de Expedición
         store_loc  TYPE lgort_d,         "Almacén
         route      TYPE route,           "Ruta
         net_pv     TYPE komv-kwert,      "Importe Neto PV
         imp_pv     TYPE komv-kwert,      "Importe Impuesto PV
         tot_pv     TYPE komv-kwert,      "Importe Total PV
         waerk_pv   TYPE vbak-waerk,      "Moneda PV
         ernam_pv   TYPE vbak-ernam,      "Usuario
         erdat_pv   TYPE vbak-erdat,      "Fecha de Creación
         erzet_pv   TYPE vbak-erzet,      "Hora de Creación

         vbeln_en   TYPE vbrk-vbeln,      "Documento de entrega
         wadat      TYPE likp-wadat_ist,  "Fecha SM Real

         erdat_en   TYPE likp-erdat,      "Fecha de Creación
         erzet_en   TYPE likp-erzet,      "Hora de Creación

         vbeln_fc   TYPE vbrk-vbeln,      "Factura
         fkdat      TYPE vbrk-fkdat,      "Fecha de Factura
         kunrg      TYPE vbrk-kunrg,      "Responsable de Pago
         knref      TYPE vbpa-knref,      "Nombre del Responsable de Pago
         net_fc     TYPE vbrk-netwr,      "Importe Neto Factura
         imp_fc     TYPE vbrk-mwsbk,      "Importe Impuesto Factura
         tot_fc     TYPE vbrk-netwr,      "Importe Total Factura
         waerk_fc   TYPE vbak-waerk,      "Moneda Factura
         ernam_fc   TYPE vbrk-ernam,      "Usuario
         erdat_fc   TYPE vbak-erdat,      "Fecha de Creación
         erzet_fc   TYPE vbak-erzet,      "Hora de Creación
         t_entrega  TYPE vbrk-vbeln,      "Doc. Entrega Temporal
         t_pos      TYPE posnr_va,        "Posicion Temporal
       END OF ty_alv.

*----------------------------------------------------------------------*
*  C L A S E S  -  D E F I N I T I O N
*----------------------------------------------------------------------*
CLASS: cls_alv_oo DEFINITION DEFERRED,
       cls_eventos DEFINITION DEFERRED.

DATA: obj_alv_oo  TYPE REF TO cls_alv_oo,
      obj_eventos TYPE REF TO cls_eventos.


*----------------------------------------------------------------------*
*  G L O B A L  -  T A B L E S / S T R U C T U  R E / V A R I A B L E S
*----------------------------------------------------------------------*
DATA: gt_alv       TYPE STANDARD TABLE OF ty_alv,
      gt_fieldcat  TYPE STANDARD TABLE OF lvc_s_fcat,
      gs_layout    TYPE lvc_s_layo,

      gt_excluding TYPE STANDARD TABLE OF ui_func,
      gs_exclude   TYPE ui_func,

      vg_container TYPE REF TO cl_gui_custom_container,
      obj_alv_grid TYPE REF TO cl_gui_alv_grid.
*      zcl_abap_util TYPE REF TO zcl_abap_util.

DATA: gv_sales_doc  TYPE bapivbeln-vbeln.

DATA: gs_filetab  TYPE filetable,                "Tabla filename
      gt_tabpop   TYPE TABLE OF sval,            "Tabla fecha
      gs_doc_fact TYPE ztsd_doc_fact,            "Estructura Docs SD
      gv_fkdat    TYPE fkdat,                    "Fecha NC
      gv_wadat    TYPE wadat,                    "Fecha de salida de mercancías
      gt_return   TYPE bapiret2_t,               "Tabla Log mensajes
      gv_answer   TYPE char1,
      gv_pass     TYPE char1,
      ok_code     TYPE sy-ucomm,
      gi_rc       TYPE i,
      gs_title    TYPE string,
      file        TYPE rlgrap-filename.


*DATA:
*       lt_styletab TYPE lvc_t_styl,
*       ls_stylerow TYPE lvc_s_styl.
*

*----------------------------------------------------------------------*
*  F I E L D  -  S Y M B O L S
*----------------------------------------------------------------------*
FIELD-SYMBOLS: <gfs_alv> TYPE ty_alv.


*----------------------------------------------------------------------*
*  C O N S T A N T S
*----------------------------------------------------------------------*
DATA: gc_x VALUE 'X' TYPE char1.


*-------------------------------------------------------------------
*           S T A R T  -  O F  -  S E L E C T I O N
*---------------------------------------------------------------------
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-001.
  PARAMETERS: p_file  TYPE string, "DEFAULT 'C:\USERS\UNG\DOWNLOADS\PROGRAMA PROCESAMIENTO FACTURAS_REQ SD 07_SET_DE_PRUEBAS_14032025V1.0.XLSX',
*              p_auart TYPE tvak-auart,  "Clase doc.ventas
*              p_vkorg TYPE tvko-vkorg,  "Organización ventas
*              p_vtweg TYPE tvtw-vtweg,  "Canal distribución
*              p_spart TYPE tspa-spart,  "Sector
*              p_vkbur TYPE tvbur-vkbur, "Oficina de ventas
*              p_vkgrp TYPE tvkgr-vkgrp, "Grupo de vendedores
              p_kschl TYPE t685a-kschl DEFAULT 'ZGAS'. "Clase de condición
SELECTION-SCREEN END OF BLOCK b01.

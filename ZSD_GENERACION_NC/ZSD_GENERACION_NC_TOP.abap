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
         "t_icon   TYPE /sapapo/ts_lock_icon,
         check    TYPE char1,           "Checkbox
         vbeln_so TYPE vbak-vbeln,      "Num. Solicitud NC
         auart    TYPE vbak-auart,      "Clase Solicitud NC
         d_auart  TYPE tvakt-bezei,     "Denom. Clase Solicitud NC
         bstkd    TYPE vbkd-bstkd,      "Referencia de Cliente
         vbeln_fa TYPE vbrk-vbeln,      "Factura Afectada
         vkorg    TYPE vbak-vkorg,      "Organización de Ventas
         d_vkorg  TYPE tvkot-vtext,     "Denominacion Org.Vtas
         vtweg    TYPE vbak-vtweg,      "Canal de Distribución
         d_vtweg  TYPE tvtwt-vtext,     "Denominacion CDist.
         spart    TYPE vbak-spart,      "Sector
         d_spart  TYPE tspat-vtext,     "Denominacion Sect.
         vkbur    TYPE vbak-vkbur,      "Oficina de Ventas
         d_vkbur  TYPE tvkbt-bezei,     "Denom. Ofic.Vtas
         kunnr    TYPE vbak-kunnr,      "Cliente
         name1    TYPE name1_gp,        "Nombre
         augru    TYPE vbak-augru,      "Motivo
         d_augru  TYPE tvaut-bezei,     "Denom.Motivo
         matnr    TYPE matnr18,         "Codigo de Material
         maktx    TYPE makt-maktx,      "Denom.Material
         kwmeng   TYPE vbap-kwmeng,     "Cantidad
         werks    TYPE vbap-werks,      "Centro Logistico
         d_werks  TYPE t001w-name1,     "Denominacion Centro
         imp_net  TYPE komv-kwert,      "Importe Neto NC
         imp_imp  TYPE komv-kwert,      "Importe Impuesto NC
         imp_tot  TYPE komv-kwert,      "Importe Total NC
         waerk    TYPE vbak-waerk,      "Moneda
         ernam    TYPE vbak-ernam,      "Usuario
         erdat    TYPE vbak-erdat,      "Fecha de Creación
         erzet    TYPE vbak-erzet,      "Hora de Creación
         vbeln_nc TYPE vbrk-vbeln,      "Nota de Credito
         kunrg    TYPE vbrk-kunrg,      "Responsable de Pago
         name2    TYPE name1_gp,        "Nombre del Responsable de Pago
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



DATA: gs_filetab TYPE filetable,                "Tabla filename
      gt_tabpop  TYPE TABLE OF sval,            "Tabla fecha
      gs_tabdoc  TYPE zparamdocsd,              "Estructura Docs SD
      gv_fkdat   TYPE fkdat,                    "Fecha NC
      gt_return  TYPE bapiret2_t,               "Tabla Log mensajes
      gv_answer  TYPE char1,
      gv_pass    TYPE char1,
      ok_code    TYPE sy-ucomm,
      gi_rc      TYPE i,
      gs_title   TYPE string,
      file       TYPE rlgrap-filename.


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
  PARAMETERS: p_file  TYPE string, "DEFAULT 'C:\Users\Ung\Desktop\NUS Consulting\ZGAS\SD_06\SD_06_-SET_DE_PRUEBAS_DEV_110_03032025.xlsx',
              p_kschl TYPE t685a-kschl DEFAULT 'ZPR1'.
SELECTION-SCREEN END OF BLOCK b01.

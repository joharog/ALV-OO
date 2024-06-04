*&---------------------------------------------------------------------*
*& Include          ZACTUALIZACION_OC_TOP
*&---------------------------------------------------------------------*

TABLES: eban , ekko, ekpo,  eket, t001, t005.

DATA: ok_code  TYPE sy-ucomm.

TYPES:
  BEGIN OF ty_data,
    bsart      LIKE   ekko-bsart,
    ebeln      LIKE   ekko-ebeln,
    ebelp      LIKE   ekpo-ebelp,
    idnlf      LIKE   ekpo-idnlf,
    matnr      LIKE   ekpo-matnr,
    dl_id      TYPE   string,
    tc_id_ext  TYPE   string,
    land1      TYPE   t001-land1,
    bukrs      TYPE   ekko-bukrs,
    tolerance  LIKE   wrf_pscd_dlhd-tolerance_ext,
    incoterm1  LIKE   wrf_pscd_dlhd-incoterm1,
    lewed      LIKE   ekpo-lewed,
    zzfabric   LIKE   ekpo-zzfabric,
    zzfrac_are LIKE   ekpo-zzfrac_are,
    zzpais_o   LIKE   ekpo-zzpais_o,
    zzpais_e   LIKE   ekpo-zzpais_e,
    zzproc_imp LIKE   ekpo-zzproc_imp,
    zznotas    LIKE   ekpo-zznotas,
    txz01      LIKE   ekpo-txz01,
    bednr      LIKE   ekpo-bednr,
    menge      LIKE   ekpo-menge,
    pais(50),
    checked(1),
    read_only  TYPE  wdy_boolean,
  END OF  ty_data.

DATA: ti_data   TYPE TABLE OF ty_data.
DATA: wa_data   LIKE LINE OF ti_data.

CONSTANTS: c_x        VALUE 'X',
           gc_refresh TYPE syucomm VALUE '&REFRESH'.




DATA: ti_global TYPE   ty_data.
DATA: wa_data3   LIKE LINE OF ti_data.
DATA: ls_global2   LIKE LINE OF ti_data.
DATA: ls_global3   LIKE LINE OF ti_data.
DATA: lt_data TYPE TABLE OF ty_data.


*------------------------------------------VARIABLES_VARIANTES_ALV
DATA: w_disvariant      TYPE disvariant,          "Varint information
      w_es_variant      LIKE disvariant,          "Manejo de variantes
      w_variant_exit(1) TYPE c,                   "Manejo de variantes
      w_repid           LIKE sy-repid.            "Para nombre del prog.

*-----------------------------------*VARIABLES_ALV
TYPE-POOLS: slis.
*CATALOGO
DATA:    i_fieldcat      TYPE  slis_t_fieldcat_alv.
DATA:    w_fieldcat      TYPE slis_fieldcat_alv.
DATA:    w_layout        TYPE slis_layout_alv.

*----------------------------------------------VARIABLES_MSJ
DATA: lt_report TYPE sy-repid.
DATA: it_listheader TYPE slis_t_listheader,
      wa_listheader TYPE slis_listheader.


DATA: lf_sp_group  TYPE slis_t_sp_group_alv, "MANEJAR GRUPOS DE CAMPOS
      lf_layout    TYPE slis_layout_alv,    "MANEJAR DISEÑO DE LAYOUT
      it_topheader TYPE slis_t_listheader,  "MANEJAR CABECERA DEL REP
      wa_top       LIKE LINE OF it_topheader. "LÍNEA PARA CABECERA
DATA: alv_git_fieldcat TYPE slis_t_fieldcat_alv WITH HEADER LINE.     "Parametros del catalogo
DATA msj TYPE string.

DATA : row    TYPE salv_de_row,
       column TYPE salv_de_column.

DATA: lv_matnr TYPE lvc_fname.

DATA: grid1  TYPE REF TO cl_gui_alv_grid.


SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME TITLE TEXT-t01.
  SELECT-OPTIONS:  s_bsart  FOR ekko-bsart  OBLIGATORY.
  SELECT-OPTIONS:  s_lifnr  FOR ekko-lifnr .
  SELECT-OPTIONS:  s_ebeln  FOR ekko-ebeln.
  SELECT-OPTIONS:  s_aedat  FOR ekko-aedat.
  SELECT-OPTIONS:  s_matkl  FOR ekpo-matkl.
  SELECT-OPTIONS:  s_matnr  FOR ekpo-matnr.
  SELECT-OPTIONS:  s_werks  FOR ekpo-werks.
  SELECT-OPTIONS:  s_bednr  FOR ekpo-bednr.
  SELECT-OPTIONS:  s_idnlf  FOR ekpo-idnlf.
SELECTION-SCREEN: END OF BLOCK b1.

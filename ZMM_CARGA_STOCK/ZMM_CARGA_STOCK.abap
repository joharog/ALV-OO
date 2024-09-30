*&---------------------------------------------------------------------*
*& Report ZMM_CARGA_STOCK
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmm_carga_stock.

INCLUDE zmm_carga_stock_top.
INCLUDE zmm_carga_stock_pbo.
INCLUDE zmm_carga_stock_pai.
INCLUDE zmm_carga_stock_f01.
INCLUDE zmm_carga_stock_cls.
*---------------------------------------------------------------------
*           S T A R T  -  O F  -  S E L E C T I O N
*---------------------------------------------------------------------
START-OF-SELECTION.

  CREATE OBJECT obj_alv_oo.

  CALL METHOD obj_alv_oo->get_data.
  CALL METHOD obj_alv_oo->show_alv.
  CALL SCREEN 0100.

  CALL METHOD obj_alv_grid->refresh_table_display.

*---------------------------------------------------------------------
*           END  -  O F  -  S E L E C T I O N
*---------------------------------------------------------------------
*END-OF-SELECTION.

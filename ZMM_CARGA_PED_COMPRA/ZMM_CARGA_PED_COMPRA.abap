*&---------------------------------------------------------------------*
*& Report MM_CARGA_PED_COMPR
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zmm_carga_ped_compra.

INCLUDE zmm_carga_ped_compra_top.
INCLUDE zmm_carga_ped_compra_pbo.
INCLUDE zmm_carga_ped_compra_pai.
INCLUDE zmm_carga_ped_compra_f01.
INCLUDE zmm_carga_ped_compra_cls.
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

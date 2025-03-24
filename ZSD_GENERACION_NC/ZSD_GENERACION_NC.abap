*&---------------------------------------------------------------------*
*& Report ZSD_GENERACION_NC
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zsd_generacion_nc.

INCLUDE zsd_generacion_nc_top.
INCLUDE zsd_generacion_nc_pbo.
INCLUDE zsd_generacion_nc_pai.
INCLUDE zsd_generacion_nc_f01.
INCLUDE zsd_generacion_nc_cls.

*---------------------------------------------------------------------
*           S T A R T  -  O F  -  S E L E C T I O N
*---------------------------------------------------------------------
START-OF-SELECTION.

  CREATE OBJECT obj_alv_oo.

  CALL METHOD obj_alv_oo->get_excel_data.
  CALL METHOD obj_alv_oo->fill_fields.
  CALL METHOD obj_alv_oo->show_alv.
  CALL SCREEN 0100.

  CALL METHOD obj_alv_grid->refresh_table_display.

*---------------------------------------------------------------------
*           END  -  O F  -  S E L E C T I O N
*---------------------------------------------------------------------
END-OF-SELECTION.

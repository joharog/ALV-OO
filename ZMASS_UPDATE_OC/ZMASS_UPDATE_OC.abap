*&---------------------------------------------------------------------*
*& Report ZACTUALIZACION_OC
*&---------------------------------------------------------------------*
REPORT zactualizacion_oc.

INCLUDE zactualizacion_oc_top.
INCLUDE zactualizacion_oc_pbo.
INCLUDE zactualizacion_oc_pai.
INCLUDE zactualizacion_oc_cl.

START-OF-SELECTION.

  CREATE OBJECT obj_alv_oo.

  CALL METHOD obj_alv_oo->get_data.
  CALL METHOD obj_alv_oo->show_alv.

  CALL SCREEN 0100.

*&---------------------------------------------------------------------*
*& Include          ZACTUALIZACION_OC_CL
*&---------------------------------------------------------------------*

DATA: it_fcat      TYPE STANDARD TABLE OF lvc_s_fcat,
      wa_fcat      TYPE lvc_s_fcat,

      it_excluding TYPE STANDARD TABLE OF ui_func,
      wa_exclude   TYPE ui_func,

      vg_container TYPE REF TO cl_gui_custom_container,
      obj_alv_grid TYPE REF TO cl_gui_alv_grid.


CLASS: cls_alv_oo DEFINITION DEFERRED,
       cls_eventos DEFINITION DEFERRED.

DATA: obj_alv_oo  TYPE REF TO cls_alv_oo,
      obj_eventos TYPE REF TO cls_eventos.


CLASS cls_alv_oo DEFINITION.

  PUBLIC SECTION.
    METHODS: get_data,
      show_alv,
      excluir_botones,
      set_fieldcat.

ENDCLASS.


CLASS cls_eventos DEFINITION.
  PUBLIC SECTION.

    METHODS:
      handle_double_click FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING e_row
                  e_column
                  es_row_no,

      handle_toolbar FOR EVENT toolbar OF cl_gui_alv_grid
        IMPORTING e_object
                  e_interactive,

      handle_user_command FOR EVENT user_command OF cl_gui_alv_grid
        IMPORTING e_ucomm.

ENDCLASS.

CLASS cls_alv_oo IMPLEMENTATION.

  METHOD: get_data.

    SET SCREEN 0.
    REFRESH: ti_data.

    SELECT * INTO TABLE @DATA(lt_ekko) FROM ekko
    WHERE bsart IN @s_bsart
      AND lifnr IN @s_lifnr
      AND ebeln IN @s_ebeln
      AND aedat IN @s_aedat.

    IF lt_ekko IS NOT INITIAL.
      SELECT * INTO TABLE @DATA(lt_t001)
        FROM t001 FOR ALL ENTRIES IN @lt_ekko
        WHERE bukrs EQ @lt_ekko-bukrs.

      SELECT * INTO TABLE @DATA(lt_ekpo) FROM ekpo
        FOR ALL ENTRIES IN @lt_ekko
        WHERE ebeln EQ @lt_ekko-ebeln.

      SELECT * INTO TABLE @DATA(lt_eket)
        FROM eket FOR ALL ENTRIES IN @lt_ekpo
        WHERE ebeln EQ @lt_ekpo-ebeln
         AND  ebelp EQ @lt_ekpo-ebelp.

      SELECT * INTO TABLE @DATA(lt_wrf)
        FROM wrf_pscd_dlhd FOR ALL ENTRIES IN @lt_eket
        WHERE dl_id EQ @lt_eket-dl_id.
    ENDIF.

    LOOP AT lt_ekpo INTO DATA(ls_ekpo).

      wa_data-lewed      = ls_ekpo-lewed.
      wa_data-zzfabric   = ls_ekpo-zzfabric.
      wa_data-zzfrac_are = ls_ekpo-zzfrac_are.
      wa_data-zzpais_o   = ls_ekpo-zzpais_o.
      wa_data-zzpais_e   = ls_ekpo-zzpais_e.

      CONCATENATE ls_ekpo-zzpais_o ls_ekpo-zzpais_e INTO wa_data-pais .

      wa_data-zzproc_imp = ls_ekpo-zzproc_imp.
      wa_data-zznotas    = ls_ekpo-zznotas.
      wa_data-txz01      = ls_ekpo-txz01.
      wa_data-bednr      = ls_ekpo-bednr.
      wa_data-menge      = ls_ekpo-menge.

      READ TABLE lt_ekko INTO DATA(ls_ekko) WITH KEY ebeln = ls_ekpo-ebeln.
      IF sy-subrc EQ 0.
        wa_data-bsart = ls_ekko-bsart.
        wa_data-ebeln = ls_ekko-ebeln.
        wa_data-ebelp = ls_ekpo-ebelp.
        wa_data-idnlf = ls_ekpo-idnlf.
        wa_data-matnr = ls_ekpo-matnr.
        wa_data-bukrs = ls_ekpo-bukrs.

        READ TABLE lt_t001 INTO DATA(ls_t001) WITH KEY bukrs = ls_ekko-bukrs.
        IF sy-subrc EQ 0.
          wa_data-land1 = ls_t001-land1.
        ENDIF.
      ENDIF.

      READ TABLE lt_eket INTO DATA(ls_eket) WITH KEY ebeln = ls_ekpo-ebeln ebelp = ls_ekpo-ebelp.
      IF sy-subrc EQ 0.
        wa_data-dl_id = ls_eket-dl_id.

        READ TABLE lt_wrf INTO DATA(ls_wrf) WITH KEY dl_id = wa_data-dl_id.
        IF sy-subrc EQ 0.
          wa_data-tolerance = ls_wrf-tolerance_ext.
          wa_data-incoterm1 = ls_wrf-incoterm1.
          wa_data-tc_id_ext = ls_wrf-tc_id_ext.
        ENDIF.
      ENDIF.

      APPEND wa_data TO ti_data.
      CLEAR: wa_data.
      SORT ti_data BY ebeln ebelp ASCENDING.

    ENDLOOP.


  ENDMETHOD.

  METHOD: show_alv.

    IF vg_container IS NOT BOUND.

      CREATE OBJECT vg_container
        EXPORTING
          container_name = 'CC_ALV'.

      CREATE OBJECT obj_alv_grid
        EXPORTING
          i_parent = vg_container.

      CALL METHOD set_fieldcat.
      CALL METHOD excluir_botones.

      CREATE OBJECT obj_eventos.
      SET HANDLER obj_eventos->handle_double_click FOR obj_alv_grid.
      SET HANDLER obj_eventos->handle_toolbar FOR obj_alv_grid.
      SET HANDLER obj_eventos->handle_user_command FOR obj_alv_grid.

      CALL METHOD obj_alv_grid->set_table_for_first_display
        EXPORTING
          it_toolbar_excluding = it_excluding
*         is_layout            = vl_layout
        CHANGING
          it_fieldcatalog      = it_fcat
          it_outtab            = ti_data.
    ELSE.
      CALL METHOD obj_alv_grid->refresh_table_display.
    ENDIF.


  ENDMETHOD.

  METHOD: excluir_botones.

    REFRESH it_excluding.

    wa_exclude = cl_gui_alv_grid=>mc_fc_info. "Atributo boton de informacion
    APPEND wa_exclude TO it_excluding.

  ENDMETHOD.

  METHOD: set_fieldcat.

*    REFRESH: it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'BSART'.
    wa_fcat-scrtext_l = 'Proveedor'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '15'.
    wa_fcat-fieldname = 'EBELN'.
    wa_fcat-scrtext_l = 'Orden de Compra'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'EBELP'.
    wa_fcat-scrtext_l = 'Posción'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '15'.
    wa_fcat-fieldname = 'IDNLF'.
    wa_fcat-scrtext_l = 'Material Proveedor'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '20'.
    wa_fcat-fieldname = 'MATNR'.
    wa_fcat-scrtext_l = 'Material'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '15'.
    wa_fcat-fieldname = 'TC_ID_EXT'.
    wa_fcat-scrtext_l = 'Cadena Transporte'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'TOLERANCE'.
    wa_fcat-scrtext_l = 'Tolerancia'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'INCOTERM1'.
    wa_fcat-scrtext_l = 'Incoterm'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'LEWED'.
    wa_fcat-scrtext_l = 'Fecha Aparador'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'ZZFABRIC'.
    wa_fcat-scrtext_l = 'Fabricante'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'ZZFRAC_ARE'.
    wa_fcat-scrtext_l = 'Fraccion'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'LAND1'.
    wa_fcat-scrtext_l = 'Pais Origen'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'ZZPROC_IMP'.
    wa_fcat-scrtext_l = 'Procedimiento Impt.'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'ZZNOTAS'.
    wa_fcat-scrtext_l = 'Transporte Importacion'.
    wa_fcat-edit      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '30'.
    wa_fcat-fieldname = 'TXZ01'.
    wa_fcat-scrtext_l = 'Texto Breve'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '15'.
    wa_fcat-fieldname = 'BEDNR'.
    wa_fcat-scrtext_l = 'Numero Necesidad'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '15'.
    wa_fcat-fieldname = 'MENGE'.
    wa_fcat-scrtext_l = 'Cantidad'.
    APPEND wa_fcat TO it_fcat.

  ENDMETHOD.
ENDCLASS.

CLASS cls_eventos IMPLEMENTATION.

  METHOD handle_double_click.

    CASE e_column.
      WHEN 'TC_ID_EXT' OR 'TOLERANCE'   OR 'INCOTERM1' OR
           'LEWED'     OR 'ZZFABRIC'    OR 'ZZFRAC_ARE' OR
           'LAND1'     OR  'ZZPROC_IMP' OR 'ZZNOTAS'.

        LOOP AT ti_data INTO DATA(ls_massive).

          DATA(lv_tabix) = sy-tabix.

          IF lv_tabix EQ 1.

            CASE e_column.

                "Cadena de Transporte
              WHEN 'TC_ID_EXT'.
                DATA(lv_temp) = ls_massive-tc_id_ext.

                "Tolerancia
              WHEN 'TOLERANCE'.
                lv_temp = ls_massive-tolerance.

                "Incoterms
              WHEN 'INCOTERM1'.
                lv_temp = ls_massive-incoterm1.

                "Fecha Aparador
              WHEN 'LEWED'.
                lv_temp = ls_massive-lewed.

                "Fabricante
              WHEN 'ZZFABRIC'.
                lv_temp = ls_massive-zzfabric.

                "Fraccion
              WHEN 'ZZFRAC_ARE'.
                lv_temp = ls_massive-lewed.

                "Pais Origen
              WHEN 'LAND1'.
                lv_temp = ls_massive-land1.

                "Procedimiento Impt.
              WHEN 'ZZPROC_IMP'.
                lv_temp = ls_massive-zzproc_imp.

                "Transporte Importacion
              WHEN 'ZZNOTAS'.
                lv_temp = ls_massive-zznotas.

            ENDCASE.

          ELSE.

            CASE e_column.
              WHEN 'TC_ID_EXT'.
                ls_massive-tc_id_ext = lv_temp.

              WHEN 'TOLERANCE'.
                ls_massive-tolerance = lv_temp.

              WHEN 'INCOTERM1'.
                ls_massive-incoterm1 = lv_temp.

              WHEN 'LEWED'.
                ls_massive-lewed = lv_temp.

              WHEN 'ZZFABRIC'.
                ls_massive-zzfabric = lv_temp.

              WHEN 'ZZFRAC_ARE'.
                ls_massive-zzfrac_are = lv_temp.

              WHEN 'LAND1'.
                ls_massive-land1 = lv_temp.

              WHEN 'ZZPROC_IMP'.
                ls_massive-zzproc_imp = lv_temp.

              WHEN 'ZZNOTAS'.
                ls_massive-zznotas = lv_temp.
            ENDCASE.

            MODIFY ti_data FROM ls_massive INDEX lv_tabix.

          ENDIF.

        ENDLOOP.

        CALL METHOD obj_alv_grid->refresh_table_display.
    ENDCASE.

  ENDMETHOD.

  METHOD handle_toolbar.
    DATA: wa_button TYPE stb_button.

    wa_button-function = 'UPDATE'.
    wa_button-icon     = icon_refresh.
    wa_button-text     = 'Actualizar'.
    wa_button-quickinfo = 'Actualizar Listado'.
*    wa_button-disabled = space.
    APPEND wa_button TO e_object->mt_toolbar.

    wa_button-function = 'CHANGE'.
    wa_button-icon     = icon_mass_change.
    wa_button-text     = 'Act. Masiva'.
    wa_button-quickinfo = 'Actualizacion Masiva'.
    APPEND wa_button TO e_object->mt_toolbar.

    wa_button-function = 'SAVE'.
    wa_button-icon     = icon_system_save.
    wa_button-text     = 'Guardar'.
    wa_button-quickinfo = 'Guardar Cambios'.
    APPEND wa_button TO e_object->mt_toolbar.

  ENDMETHOD.

  METHOD handle_user_command.

    DATA: ls_ekpo  TYPE ekpo,
          ls_t005t TYPE t005t,
          ls_eket  TYPE eket,
          ls_dlhd  TYPE wrf_pscd_dlhd.

    CASE e_ucomm.
      WHEN 'UPDATE'.
        CALL METHOD obj_alv_grid->refresh_table_display.
      WHEN 'CHANGE'.

      WHEN 'SAVE'.

        LOOP AT ti_data INTO DATA(wa_data).

          SELECT SINGLE * INTO ls_ekpo FROM ekpo
            WHERE ebeln = wa_data-ebeln
              AND ebelp = wa_data-ebelp.

          IF sy-subrc EQ 0.
            ls_ekpo-zzfrac_are  = wa_data-zzfrac_are.
            ls_ekpo-lewed       = wa_data-lewed.
            ls_ekpo-zzfabric    = wa_data-zzfabric.
            ls_ekpo-zzproc_imp  = wa_data-zzproc_imp.
            ls_ekpo-zznotas     = wa_data-zznotas.

            SELECT SINGLE * INTO ls_t005t FROM t005t
              WHERE land1 = wa_data-land1
                AND spras = 'S'.
            IF sy-subrc EQ 0.
              ls_ekpo-zzpais_o = ls_t005t-landx.
              ls_ekpo-zzpais_e = ls_t005t-landx.
            ENDIF.

*            Actualizacion EKPO
            MODIFY ekpo FROM ls_ekpo.

          ENDIF.

          SELECT SINGLE * INTO ls_eket FROM eket
            WHERE ebeln = wa_data-ebeln
              AND ebelp = wa_data-ebelp.
          IF sy-subrc EQ 0.
*            ls_eket-dl_id = wa_data-dl_id.
*            MODIFY  eket FROM   ls_eket.

            SELECT SINGLE * INTO ls_dlhd FROM wrf_pscd_dlhd
              WHERE dl_id = ls_eket-dl_id.
            IF sy-subrc EQ 0.
              ls_dlhd-tolerance_ext = wa_data-tolerance.
              ls_dlhd-incoterm1     = wa_data-incoterm1.
              ls_dlhd-tc_id_ext     = wa_data-tc_id_ext.

*            Actualizacion WRF_PSCD_DLHD
              MODIFY wrf_pscd_dlhd FROM ls_dlhd.
            ENDIF.
          ENDIF.

          CLEAR: ls_ekpo, ls_t005t, ls_eket, ls_dlhd.

        ENDLOOP.

    ENDCASE.
  ENDMETHOD.

ENDCLASS.

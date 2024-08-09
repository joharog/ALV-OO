*&---------------------------------------------------------------------*
*&  Include           ZMM_CARGA_PED_COMPRA_CLS
*&---------------------------------------------------------------------*


*----------------------------------------------------------------------*
*       CLASS cls_alv_oo DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cls_alv_oo DEFINITION.

  PUBLIC SECTION.
    METHODS: get_data,
             show_alv,
             excluir_botones,
             set_fieldcat,
             set_layout.

ENDCLASS.                    "cls_alv_oo DEFINITION

*----------------------------------------------------------------------*
*       CLASS cls_eventos DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
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

ENDCLASS.                    "cls_eventos DEFINITION


*----------------------------------------------------------------------*
*       CLASS cls_alv_oo IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cls_alv_oo IMPLEMENTATION.

  METHOD: get_data.

    SET SCREEN 0.
    REFRESH: gt_data.
    p_file = pfile.

* Upload data from Excel sheet to internal table.
    CALL FUNCTION 'ALSM_EXCEL_TO_INTERNAL_TABLE'
      EXPORTING
        filename                = p_file
        i_begin_col             = 1
        i_begin_row             = 7
        i_end_col               = 44
        i_end_row               = 9999
      TABLES
        intern                  = gt_excel
      EXCEPTIONS
        inconsistent_parameters = 1
        upload_ole              = 2
        OTHERS                  = 3.
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

*----------------------------------------------------------------------*
*   Save excel to itab
*----------------------------------------------------------------------*
    PERFORM get_itab.


*----------------------------------------------------------------------*
*   Check if exist in master data
*----------------------------------------------------------------------*
    PERFORM check_mdata.


  ENDMETHOD.                    "get_data

  METHOD: show_alv.

    IF vg_container IS NOT BOUND.

      CREATE OBJECT vg_container
        EXPORTING
          container_name = 'CC_ALV'.

      CREATE OBJECT obj_alv_grid
        EXPORTING
          i_parent = vg_container.

      CALL METHOD set_fieldcat.
      CALL METHOD set_layout.
      CALL METHOD excluir_botones.

      CREATE OBJECT obj_eventos.
      SET HANDLER obj_eventos->handle_double_click FOR obj_alv_grid.
      SET HANDLER obj_eventos->handle_toolbar FOR obj_alv_grid.
      SET HANDLER obj_eventos->handle_user_command FOR obj_alv_grid.

      CALL METHOD obj_alv_grid->set_table_for_first_display
        EXPORTING
          it_toolbar_excluding = it_excluding
          is_layout            = wa_layout
        CHANGING
          it_fieldcatalog      = it_fcat
          it_outtab            = gt_data.
    ELSE.
      CALL METHOD obj_alv_grid->refresh_table_display.
    ENDIF.

  ENDMETHOD.                    "show_alv

  METHOD: excluir_botones.

    REFRESH it_excluding.

    wa_exclude = cl_gui_alv_grid=>mc_fc_info. "Atributo boton de informacion
    APPEND wa_exclude TO it_excluding.

  ENDMETHOD.                    "excluir_botones

  METHOD: set_fieldcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '5'.
    wa_fcat-fieldname = 'SELECT'.
    wa_fcat-scrtext_s = 'Sel.'.
    wa_fcat-scrtext_l = 'Seleccionar'.
    wa_fcat-edit      = 'X'.
    wa_fcat-checkbox  = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '6'.
    wa_fcat-fieldname = 'STATUS'.
    wa_fcat-scrtext_l = 'Status'.
    wa_fcat-icon      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '40'.
    wa_fcat-fieldname = 'LOG'.
    wa_fcat-scrtext_l = 'Log'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'DOC_TYPE'.
    wa_fcat-scrtext_l = 'Clase Pedido'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '7'.
    wa_fcat-fieldname = 'COMP_CODE'.
    wa_fcat-scrtext_l = 'Sociedad'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'PURCH_ORG'.
    wa_fcat-scrtext_s = 'Org.Compras'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'PUR_GROUP'.
    wa_fcat-scrtext_s = 'Grp.Compras'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'VENDOR'.
    wa_fcat-scrtext_l = 'Proveedor'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '14'.
    wa_fcat-fieldname = 'DOC_DATE'.
    wa_fcat-scrtext_l = 'Fecha Documento'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'PMNTTRMS'.
    wa_fcat-scrtext_s = 'Cond.Pago'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '6'.
    wa_fcat-fieldname = 'CURRENCY'.
    wa_fcat-scrtext_l = 'Moneda'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'EXCH_RATE'.
    wa_fcat-scrtext_l = 'Tipo de Cambio'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '13'.
    wa_fcat-fieldname = 'EX_RATE_FX'.
    wa_fcat-scrtext_l = 'T.Cambio Fijado'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '8'.
    wa_fcat-fieldname = 'INCOTERMS1'.
    wa_fcat-scrtext_l = 'Incoterms'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'TEMP1'.
    wa_fcat-scrtext_l = 'Texto Cabecera'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'TEMP2'.
    wa_fcat-scrtext_l = 'Func.Interl.'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '8'.
    wa_fcat-fieldname = 'RETENTION_TYPE'.
    wa_fcat-scrtext_l = 'Retención'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'ACCTASSCAT'.
    wa_fcat-scrtext_l = 'Tipo Imputación'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'ITEM_CAT'.
    wa_fcat-scrtext_l = 'Tipo Posición'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '6'.
    wa_fcat-fieldname = 'PO_ITEM'.
    wa_fcat-scrtext_l = 'Posición'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'MATL_GROUP'.
    wa_fcat-scrtext_l = 'Grp. Articulos'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '20'.
    wa_fcat-fieldname = 'MATERIAL'.
    wa_fcat-scrtext_l = 'Material'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '20'.
    wa_fcat-fieldname = 'SHORT_TEXT'.
    wa_fcat-scrtext_l = 'Texto breve'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'ITM_QUANTITY'.
    wa_fcat-scrtext_l = 'Cant. Pedido'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'ITM_QUANTITY'.
    wa_fcat-scrtext_l = 'UM'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '18'.
    wa_fcat-fieldname = 'NET_PRICE'.
    wa_fcat-scrtext_l = 'Precio Neto'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '6'.
    wa_fcat-fieldname = 'PLANT'.
    wa_fcat-scrtext_l = 'Centro'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'STGE_LOC'.
    wa_fcat-scrtext_l = 'Almacén'.
    APPEND wa_fcat TO it_fcat.


    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'PREQ_NAME'.
    wa_fcat-scrtext_l = 'Solicitante'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'QUAL_INSP'.
    wa_fcat-scrtext_l = 'Tipo Stock'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'TAX_CODE'.
    wa_fcat-scrtext_l = 'Indicador Imp.'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'TEMP3'.
    wa_fcat-scrtext_l = 'Clase Condición'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'TEMP4'.
    wa_fcat-scrtext_l = 'Val.ClasCond.'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'CONF_CTRL'.
    wa_fcat-scrtext_l = 'Ctrl. Confir.'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'DELIVERY_DATE'.
    wa_fcat-scrtext_l = 'Fecha Entrega'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '8'.
    wa_fcat-fieldname = 'EXT_LINE'.
    wa_fcat-scrtext_s = 'Linea'.
    wa_fcat-scrtext_l = 'Linea SRV.'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '18'.
    wa_fcat-fieldname = 'SERVICE'.
    wa_fcat-scrtext_l = 'Servicio'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'SRV_QUANTITY'.
    wa_fcat-scrtext_l = 'Cantidad'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '7'.
    wa_fcat-fieldname = 'BASE_UOM'.
    wa_fcat-scrtext_l = 'UM base'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '15'.
    wa_fcat-fieldname = 'GR_PRICE'.
    wa_fcat-scrtext_l = 'Precio Bruto'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '7'.
    wa_fcat-fieldname = 'SERIAL_NO'.
    wa_fcat-scrtext_s = 'Imp.act.'.
    wa_fcat-scrtext_l = 'Imputación actualn'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'DISTR_PERC'.
    wa_fcat-scrtext_l = 'Distribución'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'PART_INV'.
    wa_fcat-scrtext_l = 'Fact. Parcial'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'IMP_QUANTITY'.
    wa_fcat-scrtext_l = 'Cantidad'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'COSTCENTER'.
    wa_fcat-scrtext_l = 'Centro Costos'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'GL_ACCOUNT'.
    wa_fcat-scrtext_l = 'Cuenta Mayor'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'ORDERID'.
    wa_fcat-scrtext_l = 'Orden'.
    APPEND wa_fcat TO it_fcat.

  ENDMETHOD.                    "set_fieldcat

  METHOD: set_layout.
    wa_layout-stylefname = 'FIELD_STYLE'.
  ENDMETHOD.                    "set_layout

*  METHOD: mapping_bapi.
*
*    UNASSIGN <gfs_data>.
*    LOOP AT gt_data ASSIGNING <gfs_data>.
*
*      WAIT up to 2 SECONDS.
*
*    ENDLOOP.
*
*  ENDMETHOD.                    "mapping_bapi

ENDCLASS.                    "cls_alv_oo IMPLEMENTATION


*----------------------------------------------------------------------*
*       CLASS cls_eventos IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cls_eventos IMPLEMENTATION.

  METHOD handle_double_click.


*    break e_ralarconj.
    "entro a doble click.

  ENDMETHOD.                    "handle_double_click

  METHOD handle_toolbar.

*    DATA: wa_button TYPE stb_button.
*
*    wa_button-function = 'UPDATE'.
*    wa_button-icon     = icon_refresh.
*    wa_button-text     = 'Actualizar'.
*    wa_button-quickinfo = 'Actualizar Listado'.
**    wa_button-disabled = space.
*    APPEND wa_button TO e_object->mt_toolbar.
*
*    wa_button-function = 'CHANGE'.
*    wa_button-icon     = icon_mass_change.
*    wa_button-text     = 'Act. Masiva'.
*    wa_button-quickinfo = 'Actualizacion Masiva'.
*    APPEND wa_button TO e_object->mt_toolbar.
*
*    wa_button-function = 'SAVE'.
*    wa_button-icon     = icon_system_save.
*    wa_button-text     = 'Guardar'.
*    wa_button-quickinfo = 'Guardar Cambios'.
*    APPEND wa_button TO e_object->mt_toolbar.

  ENDMETHOD.                    "handle_toolbar

  METHOD handle_user_command.

    DATA: ls_ekpo  TYPE ekpo,
          ls_t005t TYPE t005t,
          ls_eket  TYPE eket,
          ls_dlhd  TYPE wrf_pscd_dlhd.


    CASE e_ucomm.
      WHEN 'UPDATE'.

        DATA ls_ref1 TYPE REF TO cl_gui_alv_grid .

        CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
          IMPORTING
            e_grid = ls_ref1.

        CALL METHOD ls_ref1->check_changed_data.
        CALL METHOD obj_alv_grid->refresh_table_display.

      WHEN 'CHANGE'.
      WHEN 'SAVE'.

    ENDCASE.
  ENDMETHOD.                    "handle_user_command

ENDCLASS.                    "cls_eventos IMPLEMENTATION

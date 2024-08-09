*&---------------------------------------------------------------------*
*&  Include           ZMM_CARGA_STOCK_CLS
*&---------------------------------------------------------------------*

*DATA: it_fcat      TYPE STANDARD TABLE OF lvc_s_fcat,
*      wa_fcat      TYPE lvc_s_fcat,
*      wa_layout    TYPE lvc_s_layo,
*
*      it_excluding TYPE STANDARD TABLE OF ui_func,
*      wa_exclude   TYPE ui_func,
*
*      vg_container TYPE REF TO cl_gui_custom_container,
*      obj_alv_grid TYPE REF TO cl_gui_alv_grid.
*
**----------------------------------------------------------------------*
**               D E F I N I C I O N   C L A S E S
**----------------------------------------------------------------------*
*
*CLASS: cls_alv_oo DEFINITION DEFERRED,
*       cls_eventos DEFINITION DEFERRED.
*
*DATA: obj_alv_oo  TYPE REF TO cls_alv_oo,
*      obj_eventos TYPE REF TO cls_eventos.

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
        i_begin_row             = 5
        i_end_col               = 20
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
*   Populate data to internal tables and structures
*----------------------------------------------------------------------*
    SORT gt_excel BY row col.

    LOOP AT gt_excel INTO gs_excel.
      CASE gs_excel-col.
        WHEN 1.
          CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
            EXPORTING
              input  = gs_excel-value
            IMPORTING
              output = gs_data-material.
        WHEN 2. gs_data-plant       = gs_excel-value.
        WHEN 3. gs_data-stge_loc    = gs_excel-value.
        WHEN 4. gs_data-move_type   = gs_excel-value.
        WHEN 5. gs_data-val_type    = gs_excel-value.
        WHEN 6. gs_data-batch       = gs_excel-value.
        WHEN 7. gs_data-entry_qnt   = gs_excel-value.
        WHEN 8. gs_data-entry_uom   = gs_excel-value.
        WHEN 9. gs_data-amount_lc   = gs_excel-value.
        WHEN 10. gs_data-waers      = gs_excel-value.
        WHEN 11. gs_data-vprsv      = gs_excel-value.
        WHEN 12. gs_data-mlast      = gs_excel-value.
        WHEN 13. gs_data-header_txt = gs_excel-value.
        WHEN 14. gs_data-stck_type  = gs_excel-value.
        WHEN 15. gs_data-spec_stock = gs_excel-value.
        WHEN 16.
          CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
            EXPORTING
              input  = gs_excel-value
            IMPORTING
              output = gs_data-vendor.
        WHEN 17. gs_data-customer   = gs_excel-value.
        WHEN 18. gs_data-sales_ord  = gs_excel-value.
        WHEN 19.
          CALL FUNCTION 'CONVERSION_EXIT_PDATE_INPUT'
            EXPORTING
              input  = gs_excel-value
            IMPORTING
              output = gs_data-doc_date.
        WHEN 20.
          CALL FUNCTION 'CONVERSION_EXIT_PDATE_INPUT'
            EXPORTING
              input  = gs_excel-value
            IMPORTING
              output = gs_data-pstng_date.
      ENDCASE.

      AT END OF row.
        APPEND gs_data TO gt_data.
        CLEAR gs_data.
      ENDAT.

    ENDLOOP.

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
    wa_fcat-outputlen = '7'.
    wa_fcat-fieldname = 'STATUS'.
    wa_fcat-scrtext_l = 'Status'.
    wa_fcat-icon      = 'X'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '20'.
    wa_fcat-fieldname = 'LOG'.
    wa_fcat-scrtext_l = 'Log'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '18'.
    wa_fcat-fieldname = 'MATERIAL'.
    wa_fcat-scrtext_l = 'Material'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '6'.
    wa_fcat-fieldname = 'PLANT'.
    wa_fcat-scrtext_l = 'Centro'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '7'.
    wa_fcat-fieldname = 'STGE_LOC'.
    wa_fcat-scrtext_l = 'Almacén'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '7'.
    wa_fcat-fieldname = 'MOVE_TYPE'.
    wa_fcat-scrtext_s = 'Cl.Mvto.'.
    wa_fcat-scrtext_l = 'Clase de Movimiento'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'VAL_TYPE'.
    wa_fcat-scrtext_s = 'Cl.Val.'.
    wa_fcat-scrtext_l = 'Clase de Valoración'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'BATCH'.
    wa_fcat-scrtext_l = 'Lote'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'ENTRY_QNT'.
    wa_fcat-scrtext_l = 'Cantidad'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '6'.
    wa_fcat-fieldname = 'ENTRY_UOM'.
    wa_fcat-scrtext_s = 'UM'.
    wa_fcat-scrtext_l = 'Unidad de Medida'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'AMOUNT_LC'.
    wa_fcat-scrtext_s = 'Impt.ML'.
    wa_fcat-scrtext_l = 'Importe ML'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '7'.
    wa_fcat-fieldname = 'WAERS'.
    wa_fcat-scrtext_l = 'Moneda'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'VPRSV'.
    wa_fcat-scrtext_l = 'Ctrol.precio'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'MLAST'.
    wa_fcat-scrtext_l = 'Determ.precio'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '20'.
    wa_fcat-fieldname = 'HEADER_TXT'.
    wa_fcat-scrtext_l = 'Texto Cabecera Documento'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'STCK_TYPE'.
    wa_fcat-scrtext_l = 'Tipo Stock'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'SPEC_STOCK'.
    wa_fcat-scrtext_s = 'Ind. StockEsp.'.
    wa_fcat-scrtext_l = 'Indicador Stock Especial'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'VENDOR'.
    wa_fcat-scrtext_l = 'Proveedor'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '12'.
    wa_fcat-fieldname = 'CUSTOMER'.
    wa_fcat-scrtext_l = 'Cliente'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '8'.
    wa_fcat-fieldname = 'RETENTION_TYPE'.
    wa_fcat-scrtext_l = 'Retención'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'SALES_ORD'.
    wa_fcat-scrtext_s = 'Ped.Venta'.
    wa_fcat-scrtext_l = 'Pedido de Venta'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'DOC_DATE'.
    wa_fcat-scrtext_s = 'F.Doc.'.
    wa_fcat-scrtext_l = 'Fecha Documento'.
    APPEND wa_fcat TO it_fcat.

    CLEAR: wa_fcat.
    wa_fcat-outputlen = '10'.
    wa_fcat-fieldname = 'PSTNG_DATE'.
    wa_fcat-scrtext_s = 'F.Contb.'.
    wa_fcat-scrtext_l = 'Fecha Contabilización'.
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

*    clear: ls_data.
*
*    CASE e_column.
*    	WHEN 'LOG'.
*        READ TABLE gt_data INDEX e_row-index INTO ls_data.
*        IF sy-subrc eq 0.
*
*        ENDIF.
*
*    	WHEN OTHERS.
*    ENDCASE.
*
*    READ TABLE gt_data INDEX e_row-index INTO ls_sflight.


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

*    DATA: ls_ekpo  TYPE ekpo,
*          ls_t005t TYPE t005t,
*          ls_eket  TYPE eket,
*          ls_dlhd  TYPE wrf_pscd_dlhd.
*
*    CASE e_ucomm.
*      WHEN 'UPDATE'.
*
*        DATA ls_ref1 TYPE REF TO cl_gui_alv_grid .
*
*        CALL FUNCTION 'GET_GLOBALS_FROM_SLVC_FULLSCR'
*          IMPORTING
*            e_grid = ls_ref1.
*
*        CALL METHOD ls_ref1->check_changed_data.
*
*
*        break e_ralarconj.
*        "entro a botones
*        CALL METHOD obj_alv_grid->refresh_table_display.
*      WHEN 'CHANGE'.
*        break e_ralarconj.
*        "entro a botones
*
*      WHEN 'SAVE'.
*        break e_ralarconj.
*        "entro a botones
*    ENDCASE.

  ENDMETHOD.                    "handle_user_command

ENDCLASS.                    "cls_eventos IMPLEMENTATION

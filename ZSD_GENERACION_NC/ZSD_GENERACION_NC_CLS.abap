*&---------------------------------------------------------------------*
*& Include          ZSD_GENERACION_NC_CLS
*&---------------------------------------------------------------------*


*----------------------------------------------------------------------*
*       CLASS cls_alv_oo DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cls_alv_oo DEFINITION.

  PUBLIC SECTION.
*    TYPES: BEGIN OF ty_alv,
*             check    TYPE char1,           "Checkbox
*             vbeln_so TYPE vbak-vbeln,      "Num. Solicitud NC
*             auart    TYPE vbak-auart,      "Clase Solicitud NC
*             d_auart  TYPE tvakt-bezei,     "Denom. Clase Solicitud NC
*             vbeln_fa    TYPE vbak-vbeln_fa,      "Factura Afectada
*             vkorg    TYPE vbak-vkorg,      "Organización de Ventas
*             d_vkorg  TYPE tvkot-vtext,     "Denominacion Org.Vtas
*             vtweg    TYPE vbak-vtweg,      "Canal de Distribución
*             d_vtweg  TYPE tvtwt-vtext,     "Denominacion CDist.
*             spart    TYPE vbak-spart,      "Sector
*             d_spart  TYPE tspat-vtext,     "Denominacion Sect.
*             vkbur    TYPE vbak-vkbur,      "Oficina de Ventas
*             d_vkbur  TYPE tvkbt-bezei,     "Denom. Ofic.Vtas
*             kunnr    TYPE vbak-kunnr,      "Cliente
*             name1    TYPE name1_gp,        "Nombre
*             augru    TYPE vbak-augru,      "Motivo
*             d_augru  TYPE tvaut-bezei,     "Denom.Motivo
*             matnr    TYPE matnr18,         "Codigo de Material
*             maktx    TYPE makt-maktx,      "Denom.Material
*             kwmeng   TYPE vbap-kwmeng,     "Cantidad
*             werks    TYPE vbap-werks,      "Centro Logistico
*             d_werks  TYPE t001w-name1,     "Denominacion Centro
*             imp_net  TYPE komv-kwert,      "Importe Neto NC
*             imp_imp  TYPE komv-kwert,      "Importe Impuesto NC
*             imp_tot  TYPE komv-kwert,      "Importe Total NC
*             waerk    TYPE vbak-waerk,      "Moneda
*             ernam    TYPE vbak-ernam,      "Usuario
*             erdat    TYPE vbak-erdat,      "Fecha de Creación
*             erzet    TYPE vbak-erzet,      "Hora de Creación
*             vbeln_nc TYPE vbrk-vbeln,      "Nota de Credito
*             kunrg    TYPE vbrk-kunrg,      "Responsable de Pago
*             name2    TYPE name1_gp,        "Nombre del Responsable de Pago
*           END OF ty_alv.
*
*    DATA: lt_alv TYPE TABLE OF ty_alv,
*          ls_alv TYPE ty_alv.


    TYPES: tt_spreadsheet_by_sheetname
           TYPE STANDARD TABLE OF if_mass_spreadsheet_types=>s_spreadsheet_by_sheetname
           WITH DEFAULT KEY.


    METHODS: get_excel_data,
      fill_fields,
      show_alv,
      set_fieldcat,
      set_layout,
      excluir_botones.


    CLASS-DATA:
        st_data TYPE tt_spreadsheet_by_sheetname.



  PRIVATE SECTION.
    DATA: lt_worksheets TYPE zcl_abap_util=>tt_worksheets.
    DATA: osalv         TYPE REF TO cl_salv_table.

ENDCLASS.                    "cls_alv_oo DEFINITION

*----------------------------------------------------------------------*
*       CLASS cls_eventos DEFINITION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cls_eventos DEFINITION.
  PUBLIC SECTION.

    METHODS:
*      handle_double_click FOR EVENT double_click OF cl_gui_alv_grid
*        IMPORTING e_row
*                  e_column
*                  es_row_no,
*
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

  METHOD: get_excel_data.

    lt_worksheets = zcl_abap_util=>xls_to_itab( p_file ).

    TRY.
        CHECK lt_worksheets IS NOT INITIAL.
        DATA(ls_worksheet) = lt_worksheets[ 1 ]. "Selecionar pestaña excel

        FIELD-SYMBOLS <lt_worksheet> TYPE STANDARD TABLE.
        ASSIGN ls_worksheet-itab->* TO <lt_worksheet>.

        LOOP AT <lt_worksheet> ASSIGNING FIELD-SYMBOL(<fs_line>) FROM 9.  "Tomar a partir de la fila 8
          APPEND INITIAL LINE TO gt_alv ASSIGNING FIELD-SYMBOL(<fs_record>).
          zcl_abap_util=>move_fields(
            CHANGING
              cs_line   = <fs_line>
              cs_record = <fs_record> ).

        ENDLOOP.

        IF osalv IS INITIAL.
          cl_salv_table=>factory(
            IMPORTING
              r_salv_table = osalv
            CHANGING
              t_table      = gt_alv ).
        ENDIF.

      CATCH cx_salv_msg cx_salv_data_error cx_salv_not_found cx_fdt_excel_core INTO DATA(oerror).
        MESSAGE oerror TYPE 'I'. " RAISING ex_failed.
    ENDTRY.

*    Elimnar registros si no vienen con Clase Solicitud NC.
    DELETE gt_alv WHERE auart IS INITIAL.

  ENDMETHOD.                    "get_excel_ data

  METHOD: fill_fields.

    UNASSIGN <gfs_alv>.
    DATA ls_return TYPE bapiret2.
    REFRESH: gt_return.

    LOOP AT gt_alv ASSIGNING <gfs_alv>.

      <gfs_alv>-vbeln_fa = |{ <gfs_alv>-vbeln_fa ALPHA = IN }|.
      <gfs_alv>-kunnr = |{ <gfs_alv>-kunnr ALPHA = IN }|.

      SELECT SINGLE name1 FROM t001w INTO <gfs_alv>-d_werks
        WHERE werks EQ <gfs_alv>-werks.

      IF <gfs_alv>-vbeln_fa IS NOT INITIAL.

        SELECT SINGLE * FROM vbrk INTO @DATA(ls_vbrk)
          WHERE vbeln EQ @<gfs_alv>-vbeln_fa
            AND kunrg EQ @<gfs_alv>-kunnr.
        IF sy-subrc NE 0.

          APPEND VALUE #( type       = 'E'
                          id         = 'ZMSG_GENDOCS'
                          number     = 001
                          message_v1 = <gfs_alv>-vbeln_fa
                          message_v2 = <gfs_alv>-kunnr )
                          TO gt_return.
          <gfs_alv>-vbeln_so = icon_led_red.

        ELSE.
          IF ls_vbrk-netwr LE <gfs_alv>-imp_net.
            APPEND VALUE #( type       = 'E'
                            id         = 'ZMSG_GENDOCS'
                            number     = 002 )
                            TO gt_return.
            <gfs_alv>-vbeln_so = icon_led_red.
          ENDIF.
        ENDIF.

      ELSE.
        APPEND VALUE #( type       = 'E'
                        id         = 'ZMSG_GENDOCS'
                        number     = 003 )
                        TO gt_return.
        <gfs_alv>-vbeln_so = icon_led_red.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.                    "fill_fields


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
*      SET HANDLER obj_eventos->handle_double_click FOR obj_alv_grid.
      SET HANDLER obj_eventos->handle_toolbar FOR obj_alv_grid.
      SET HANDLER obj_eventos->handle_user_command FOR obj_alv_grid.

      CALL METHOD obj_alv_grid->set_table_for_first_display
        EXPORTING
          it_toolbar_excluding = gt_excluding
          is_layout            = gs_layout
        CHANGING
          it_fieldcatalog      = gt_fieldcat
          it_outtab            = gt_alv.
    ELSE.
      CALL METHOD obj_alv_grid->refresh_table_display.
    ENDIF.

  ENDMETHOD.                    "show_alv


  METHOD: excluir_botones.

    REFRESH gt_excluding.
    gs_exclude = cl_gui_alv_grid=>mc_fc_info. "Atributo boton de informacion
    APPEND gs_exclude TO gt_excluding.

  ENDMETHOD.                    "excluir_botones
*
  METHOD: set_fieldcat.

    APPEND VALUE #( outputlen = '5'
                    fieldname = 'CHECK'
                    scrtext_s = 'Sel.'
                    scrtext_l = 'Seleccionar'
                    edit      = abap_true
                    checkbox  = abap_true )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'VBELN_SO'
                    scrtext_l = 'Num. Solicitud NC' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'VBELN_NC'
                    scrtext_l = 'Nota de Credito' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'AUART'
                    scrtext_l = 'Clase Solicitud NC' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_AUART'
                    scrtext_l = 'Denom. Clase Solicitud NC' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'BSTKD'
                    scrtext_s = 'Ref.Cliente'
                    scrtext_l = 'Referencia de Cliente' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'vbeln_fa'
                    scrtext_l = 'Factura Afectada' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '8'
                    fieldname = 'VKORG'
                    scrtext_s = 'Org. Ventas'
                    scrtext_l = 'Organización de Ventas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_VKORG'
                    scrtext_s = 'Den.Org.Vtas'
                    scrtext_l = 'Denominación Org.Vtas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '12'
                    fieldname = 'VTWEG'
                    scrtext_s = 'Canal Dist.'
                    scrtext_l = 'Canal de Distribución' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_VTWEG'
                    scrtext_s = 'Den.Canal.Dist.'
                    scrtext_l = 'Denominación CDist.' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'SPART'
                    scrtext_s = 'Sector'
                    scrtext_l = 'Sector' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'D_SPART'
                    scrtext_s = 'Den.Sector'
                    scrtext_l = 'Denominación Sect.' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'VKBUR'
                    scrtext_s = 'Ofic.Ventas'
                    scrtext_l = 'Oficina de Ventas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_VKBUR'
                    scrtext_s = 'Denom.Ofic.Vtas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'KUNNR'
                    scrtext_s = 'Cliente' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'NAME1'
                    scrtext_s = 'Nombre' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'AUGRU'
                    scrtext_s = 'Motivo' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'D_AUGRU'
                    scrtext_s = 'Denom.Motivo' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'MATNR'
                    scrtext_s = 'Material'
                    scrtext_l = 'Cod.Material' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'MAKTX'
                    scrtext_l = 'Denom.Material' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'KWMENG'
                    scrtext_s = 'Cantidad' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'WERKS'
                    scrtext_s = 'Centro' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'D_WERKS'
                    scrtext_l = 'Denom.Centro' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'IMP_NET'
                    scrtext_l = 'Importe Neto NC' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'IMP_IMP'
                    scrtext_l = 'Importe Impuesto NC' )
                    TO gt_fieldcat.
    APPEND VALUE #( outputlen = '15'
                    fieldname = 'IMP_TOT'
                    scrtext_l = 'Importe Total NC' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'WAERK'
                    scrtext_s = 'Moneda' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'ERNAM'
                    scrtext_s = 'Usuario' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERDAT'
                    scrtext_l = 'Fecha Creación' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERZET'
                    scrtext_l = 'Hora Creación' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'KUNRG'
                    scrtext_l = 'Responsable de Pago' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'NAME2'
                    scrtext_l = 'Nomb.Respon.Pago' )
                    TO gt_fieldcat.

  ENDMETHOD.                    "set_fieldcat

  METHOD: set_layout.

    gs_layout = VALUE #( stylefname = 'FIELD_STYLE' ).
*                         box_fname = 'SELECT'

  ENDMETHOD.                    "set_layout

ENDCLASS.                    "cls_alv_oo IMPLEMENTATION


*----------------------------------------------------------------------*
*       CLASS cls_eventos IMPLEMENTATION
*----------------------------------------------------------------------*
*
*----------------------------------------------------------------------*
CLASS cls_eventos IMPLEMENTATION.

*  METHOD handle_double_click.

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

*  ENDMETHOD.                    "handle_double_click

  METHOD handle_toolbar.

    DATA: ls_toolbar TYPE stb_button.

    CLEAR ls_toolbar.
    MOVE 0 TO ls_toolbar-butn_type.
    MOVE 'SEL_ALL' TO ls_toolbar-function.
    MOVE icon_select_all TO ls_toolbar-icon.
    MOVE 'Marcar todo' TO ls_toolbar-quickinfo.
    MOVE ' ' TO ls_toolbar-disabled.
*    APPEND ls_toolbar TO e_object->mt_toolbar.
    INSERT ls_toolbar INTO e_object->mt_toolbar INDEX 3. " !!!

    CLEAR ls_toolbar.
    MOVE 0 TO ls_toolbar-butn_type.
    MOVE 'DES_ALL' TO ls_toolbar-function.
    MOVE icon_deselect_all TO ls_toolbar-icon.
    MOVE 'Desmarcar todo' TO ls_toolbar-quickinfo.
    MOVE ' ' TO ls_toolbar-disabled.
*    APPEND ls_toolbar TO e_object->mt_toolbar.
    INSERT ls_toolbar INTO e_object->mt_toolbar INDEX 4. " !!!

    CLEAR ls_toolbar.
    MOVE 3 TO ls_toolbar-butn_type.
    MOVE ' ' TO ls_toolbar-disabled.
*    APPEND ls_toolbar TO e_object->mt_toolbar.
    INSERT ls_toolbar INTO e_object->mt_toolbar INDEX 5. " !!!


  ENDMETHOD.                    "handle_toolbar


  METHOD handle_user_command.

    CASE e_ucomm.
      WHEN 'SEL_ALL'.
        LOOP AT gt_alv ASSIGNING <gfs_alv>. "WHERE log IS INITIAL.
          <gfs_alv>-check = 'X'.
        ENDLOOP.
      WHEN 'DES_ALL'.
        LOOP AT gt_alv ASSIGNING <gfs_alv>. "WHERE log IS INITIAL.
          <gfs_alv>-check = ''.
        ENDLOOP.
    ENDCASE.

    CALL METHOD obj_alv_grid->refresh_table_display.

  ENDMETHOD.                    "handle_user_command

ENDCLASS.                    "cls_eventos IMPLEMENTATION

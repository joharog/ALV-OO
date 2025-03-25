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

        LOOP AT <lt_worksheet> ASSIGNING FIELD-SYMBOL(<fs_line>) FROM 8.  "Tomar a partir de la fila 8
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

*    Elimnar registros si no vienen con Posicion
    DELETE gt_alv WHERE itm_number IS INITIAL.

  ENDMETHOD.                    "get_excel_ data

  METHOD: fill_fields.

    DATA: keep_pos TYPE posnr_va,
          save_pos TYPE i.
*    DATA ls_return TYPE bapiret2.
*    REFRESH: gt_return.

    UNASSIGN <gfs_alv>.

    LOOP AT gt_alv ASSIGNING <gfs_alv>.

      <gfs_alv>-matnr = |{ <gfs_alv>-matnr ALPHA = IN }|.
      <gfs_alv>-kunnr = |{ <gfs_alv>-kunnr ALPHA = IN }|.

*     Start counter
      IF <gfs_alv>-itm_number EQ 000010.
        keep_pos = <gfs_alv>-itm_number.
        save_pos += 1.
      ENDIF.

      IF <gfs_alv>-itm_number EQ keep_pos.
        keep_pos += 000010.
        <gfs_alv>-t_pos = save_pos.
      ENDIF.

      SELECT SINGLE vtext FROM tvtwt INTO <gfs_alv>-d_vtweg
        WHERE vtweg EQ <gfs_alv>-vtweg
          AND spras EQ sy-langu.

      SELECT SINGLE bezei FROM tvkbt INTO <gfs_alv>-d_vkbur
        WHERE vkbur EQ <gfs_alv>-vkbur
          AND spras EQ sy-langu.

      SELECT SINGLE name1 FROM kna1 INTO <gfs_alv>-name1
        WHERE kunnr EQ <gfs_alv>-kunnr.

      SELECT SINGLE maktx FROM makt INTO <gfs_alv>-maktx
        WHERE matnr EQ <gfs_alv>-matnr.

      SELECT SINGLE vtext FROM tvstt INTO <gfs_alv>-d_vstel
        WHERE vstel EQ <gfs_alv>-ship_point
          AND spras EQ sy-langu.

      SELECT SINGLE vtext FROM tspat INTO <gfs_alv>-d_spart
        WHERE spart EQ <gfs_alv>-spart
          AND spras EQ sy-langu.

    ENDLOOP.


*      <gfs_alv>-vbeln_fa = |{ <gfs_alv>-vbeln_fa ALPHA = IN }|.
*      <gfs_alv>-kunnr = |{ <gfs_alv>-kunnr ALPHA = IN }|.
*
*      SELECT SINGLE name1 FROM t001w INTO <gfs_alv>-d_werks
*        WHERE werks EQ <gfs_alv>-werks.
*
*      IF <gfs_alv>-vbeln_fa IS NOT INITIAL.
*
*        SELECT SINGLE * FROM vbrk INTO @DATA(ls_vbrk)
*          WHERE vbeln EQ @<gfs_alv>-vbeln_fa
*            AND kunrg EQ @<gfs_alv>-kunnr.
*        IF sy-subrc NE 0.
*
*          APPEND VALUE #( type       = 'E'
*                          id         = 'ZMSG_GENDOCS'
*                          number     = 001
*                          message_v1 = <gfs_alv>-vbeln_fa
*                          message_v2 = <gfs_alv>-kunnr )
*                          TO gt_return.
*          <gfs_alv>-vbeln_so = icon_led_red.
*
*        ELSE.
*          IF ls_vbrk-netwr LE <gfs_alv>-imp_net.
*            APPEND VALUE #( type       = 'E'
*                            id         = 'ZMSG_GENDOCS'
*                            number     = 002 )
*                            TO gt_return.
*            <gfs_alv>-vbeln_so = icon_led_red.
*          ENDIF.
*        ENDIF.
*
*      ELSE.
*        APPEND VALUE #( type       = 'E'
*                        id         = 'ZMSG_GENDOCS'
*                        number     = 003 )
*                        TO gt_return.
*        <gfs_alv>-vbeln_so = icon_led_red.
*      ENDIF.
*
*    ENDLOOP.

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

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'VBELN_PV'
                    scrtext_m = 'Num.PV'
                    scrtext_l = 'Num.PedidoVtas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'VBELN_EN'
                    scrtext_m = 'Doc.entrega'
                    scrtext_l = 'Documento de entrega' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'VBELN_FC'
                    scrtext_m = 'Factura' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'AUART'
                    scrtext_s = 'Clase PV'
                    scrtext_l = 'Clase Pedido de Ventas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_AUART'
                    scrtext_s = 'Denom.Clase.PV'
                    scrtext_l = 'Denom. Clase Solicitud PV' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'VKORG'
                    scrtext_m = 'Org. Ventas'
                    scrtext_l = 'Organización de Ventas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_VKORG'
                    scrtext_s = 'Den.Org.Vtas'
                    scrtext_l = 'Denominación Org.Vtas' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'VTWEG'
                    scrtext_m = 'Canal Dist.'
                    scrtext_l = 'Canal de Distribución' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_VTWEG'
                    scrtext_m = 'Den.Canal.Dist.'
                    scrtext_l = 'Denominación CDist.' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '7'
                    fieldname = 'SPART'
                    scrtext_s = 'Sector'
                    scrtext_l = 'Sector' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
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
                    fieldname = 'BSTKD'
                    scrtext_m = 'Ref.Cliente'
                    scrtext_l = 'Referencia de Cliente' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'KUNNR'
                    scrtext_s = 'Cliente' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'NAME1'
                    scrtext_s = 'Nom.Cliente'
                    scrtext_l = 'Nombre Cliente' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ITM_NUMBER'
                    scrtext_s = 'Pos.'
                    scrtext_l = 'Posicion' )
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

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'TARGET_QTY'
                    scrtext_l = 'Cantidad' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '7'
                    fieldname = 'TARGET_QU'
                    scrtext_s = 'UM'
                    scrtext_l = 'Unidad de Medida' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'BATCH'
                    scrtext_s = 'Lote' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'PLANT'
                    scrtext_s = 'Centro' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'SHIP_POINT'
                    scrtext_s = 'Puesto Exp.'
                    scrtext_l = 'Puesto de Expedición' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '20'
                    fieldname = 'D_VSTEL'
                    scrtext_s = 'Den.Puesto.Exp'
                    scrtext_l = 'Denom.Puesto.Exp' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'STORE_LOC'
                    scrtext_s = 'Almacén' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'ROUTE'
                    scrtext_s = 'Ruta' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'NET_PV'
                    scrtext_l = 'Importe Neto PV' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'IMP_PV'
                    scrtext_l = 'Importe Impuesto PV' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'TOT_PV'
                    scrtext_l = 'Importe Total PV' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'WAERK_PV'
                    scrtext_s = 'Moneda' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'ERNAM_PV'
                    scrtext_s = 'Usuario' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERDAT_PV'
                    scrtext_l = 'Fecha Creación' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERZET_PV'
                    scrtext_l = 'Hora Creación' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'WADAT'
                    scrtext_l = 'Fecha SM Real' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERDAT_EN'
                    scrtext_l = 'Fecha Creación' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERZET_EN'
                    scrtext_l = 'Hora Creación' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'FKDAT'
                    scrtext_l = 'Fecha Factura' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'KUNRG'
                    scrtext_s = 'Resp.Pago'
                    scrtext_l = 'Responsable de Pago' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'KNREF'
                    scrtext_s = 'Nom.Resp.Pago'
                    scrtext_l = 'Nombre del Responsable de Pago' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'NET_FC'
                    scrtext_l = 'Importe Neto Factura' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'IMP_FC'
                    scrtext_l = 'Importe Impuesto Factura' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'TOT_FC'
                    scrtext_l = 'Importe Total Factura' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'WAERK_FC'
                    scrtext_s = 'Mon.Factura'
                    scrtext_l = 'Moneda Factura' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '10'
                    fieldname = 'ERNAM_FC'
                    scrtext_s = 'Usuario' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERDAT_FC'
                    scrtext_l = 'Fecha Creación' )
                    TO gt_fieldcat.

    APPEND VALUE #( outputlen = '15'
                    fieldname = 'ERZET_FC'
                    scrtext_l = 'Hora Creación' )
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

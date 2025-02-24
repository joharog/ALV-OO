*&----------------------------------------------------------------------------*
*& Report ZPR_CARGA_MIRO_FACTURAS
*-----------------------------------------------------------------------------*
* Título         : Nombre del GAP: Carga masiva facturas (MIRO) vía plantilla *
* Autor          : Consultor                                                  *
* Fecha creación : 25/Enero/2025                                              *
* Módulo         : MM                                                         *
*&----------------------------------------------------------------------------*
REPORT zpr_carga_miro_facturas.

INCLUDE zpr_carga_miro_facturas_top.
INCLUDE zpr_carga_miro_facturas_sel.
INCLUDE zpr_carga_miro_facturas_f01.
INCLUDE zpr_carga_miro_facturas_f02.

START-OF-SELECTION.

  IF r_down EQ abap_true.
    PERFORM fill_data.

  ELSEIF r_up EQ abap_true.
    TRY.
        DATA(oalv) = NEW lcl_alv( ).
        oalv->get_excel_data( p_file ).
        oalv->show_alv( ).

      CATCH cx_root INTO DATA(oerror).
        MESSAGE oerror->get_text( ) TYPE 'E' DISPLAY LIKE 'I'.

    ENDTRY.
  ENDIF.

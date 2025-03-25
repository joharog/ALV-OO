*&---------------------------------------------------------------------*
*& Include          ZSD_GENERACION_NC_PAI
*&---------------------------------------------------------------------*

*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CALL METHOD obj_alv_grid->check_changed_data.

  CLEAR: gv_pass.

  CASE ok_code.

    WHEN 'E' OR '&F03'.
      LEAVE TO SCREEN 0.
    WHEN 'ENDE' OR '&F15'.
      LEAVE TO SCREEN 0.
    WHEN 'ECAN' OR '&F12'.
      LEAVE TO SCREEN 0.

    WHEN '&LOG'.
      zcl_abap_util=>show_log( gt_return ).

    WHEN '&GEN_PV'.

      READ TABLE gt_alv TRANSPORTING NO FIELDS WITH KEY check = abap_true vbeln_pv = ''.
      IF sy-subrc EQ 0.

        CLEAR: gv_answer.

        CALL FUNCTION 'POPUP_TO_CONFIRM'
          EXPORTING
            titlebar              = 'Confirmación '
            text_question         = '¿Quieres generar Num.Pedido de Ventas para las filas selecionadas?'
            text_button_1         = 'Si'
            icon_button_1         = 'ICON_CHECKED'
            text_button_2         = 'No'
            icon_button_2         = 'ICON_CANCEL'
            display_cancel_button = ' '
            popup_type            = 'ICON_MESSAGE_ERROR'
          IMPORTING
            answer                = gv_answer.
        IF gv_answer NE 1.
          LEAVE SCREEN.

        ELSE.
          PERFORM gen_pv.

        ENDIF.

      ELSE.

        MESSAGE 'Debe selecionar al menos un registro sin Num.Pedido de Ventas generado' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    WHEN '&CON_PV'.

      CLEAR: gv_pass.

      LOOP AT gt_alv TRANSPORTING NO FIELDS WHERE check EQ abap_true AND t_entrega EQ '' AND ( vbeln_pv NE icon_led_red AND vbeln_pv NE '' ).
        gv_pass = abap_true.
        EXIT.
      ENDLOOP.

      IF gv_pass EQ abap_true.

*        REFRESH: gt_tabpop.
*
*        APPEND VALUE #( tabname   = 'LIKP'
*                        fieldname = 'WADAT_IST' )
*                        TO gt_tabpop.
*
*        CALL FUNCTION 'POPUP_GET_VALUES'
*          EXPORTING
*            popup_title     = 'Fecha SM en Entrega:'
*          TABLES
*            fields          = gt_tabpop
*          EXCEPTIONS
*            error_in_fields = 1
*            OTHERS          = 2.
*
*        READ TABLE gt_tabpop INTO DATA(ls_tabpop) INDEX 1.
*        IF sy-subrc = 0.
*          gv_fkdat = ls_tabpop-value.
        PERFORM con_pv.
        MESSAGE 'Contabilización procesada, por favor verificar log de mensajes' TYPE 'S' DISPLAY LIKE 'W'.
*        ENDIF.

      ELSE.

        MESSAGE 'Debe selecionar al menos un registro que tenga Num.Pedido de Ventas y Doc. entrega no generado' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

    WHEN '&GEN_FACT'.

      CLEAR: gv_pass.

      LOOP AT gt_alv TRANSPORTING NO FIELDS WHERE check EQ abap_true AND vbeln_fc EQ '' AND ( vbeln_pv NE icon_led_red AND vbeln_pv NE '' AND
                                                                                              vbeln_en NE icon_led_red AND vbeln_en NE '' ).
        gv_pass = abap_true.
        EXIT.
      ENDLOOP.

      IF gv_pass EQ abap_true.

        REFRESH: gt_tabpop.

        APPEND VALUE #( tabname   = 'VBRK'
                        fieldname = 'FKDAT'
                        field_obl = gc_x )
                        TO gt_tabpop.

        CALL FUNCTION 'POPUP_GET_VALUES'
          EXPORTING
            popup_title     = 'Fecha de Factura:'
          TABLES
            fields          = gt_tabpop
          EXCEPTIONS
            error_in_fields = 1
            OTHERS          = 2.

        READ TABLE gt_tabpop INTO DATA(ls_tabpop) INDEX 1.
        IF sy-subrc = 0 AND ls_tabpop-value IS NOT INITIAL.
          gv_fkdat = ls_tabpop-value.
          PERFORM gen_fact.
        ELSE.
          LEAVE SCREEN.
        ENDIF.

      ELSE.

        MESSAGE 'Debe selecionar al menos un registro que tenga Num.Pedido de Ventas y Doc. entrega' TYPE 'S' DISPLAY LIKE 'E'.
      ENDIF.

  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT

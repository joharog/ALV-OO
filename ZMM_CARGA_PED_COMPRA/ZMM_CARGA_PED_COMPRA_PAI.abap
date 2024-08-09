*----------------------------------------------------------------------*
***INCLUDE ZMM_CARGA_PED_COMPRA_PAI .
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*&      Module  USER_COMMAND_0100  INPUT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
MODULE user_command_0100 INPUT.

  CASE ok_code.
    WHEN 'E' OR '&F03'.
      LEAVE TO SCREEN 0.
    WHEN 'ENDE' OR '&F15'.
      LEAVE TO SCREEN 0.
    WHEN 'ECAN' OR '&F12'.
      LEAVE TO SCREEN 0.

    WHEN '&CARGA_PO'.

      CLEAR: gv_answer.

      CALL FUNCTION 'POPUP_TO_CONFIRM'
        EXPORTING
          titlebar              = 'Confirmación '
          text_question         = '¿Quieres cargar los pedidos de compra selecionados?'
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
        PERFORM carga_po.
        CALL METHOD obj_alv_grid->refresh_table_display.
      ENDIF.


  ENDCASE.

ENDMODULE.                 " USER_COMMAND_0100  INPUT

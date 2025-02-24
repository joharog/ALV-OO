*&---------------------------------------------------------------------*
*& Include          ZPR_CARGA_MIRO_FACTURAS_SEL
*&---------------------------------------------------------------------*
SELECTION-SCREEN BEGIN OF BLOCK b01 WITH FRAME TITLE TEXT-b01.
  SELECT-OPTIONS: s_ebeln FOR ekko-ebeln MODIF ID aa.
  PARAMETERS:     p_bukrs LIKE ekko-bukrs MODIF ID aa.
  PARAMETERS: p_file TYPE /isdfps/sv_filename LOWER CASE MEMORY ID /pf1/p_file_name MODIF ID bb.

  PARAMETERS: r_down TYPE c RADIOBUTTON GROUP rb1 DEFAULT 'X' USER-COMMAND u1,
              r_up   TYPE c RADIOBUTTON GROUP rb1.
SELECTION-SCREEN END OF BLOCK b01.


SELECTION-SCREEN FUNCTION KEY 1.

INITIALIZATION.
  sscrfields-functxt_01 = TEXT-m01.
  CALL METHOD cl_gui_frontend_services=>get_desktop_directory(
    CHANGING
      desktop_directory = dir
    EXCEPTIONS
      OTHERS            = 4 ##SUBRC_OK
  ).
  CALL METHOD cl_gui_cfw=>update_view.


* Ocultar seleccion por radio button
AT SELECTION-SCREEN OUTPUT.
  LOOP AT SCREEN.
    IF r_down EQ 'X'.
      REFRESH s_ebeln. CLEAR p_bukrs.
      IF screen-group1 EQ 'BB'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
    ELSEIF r_up EQ 'X'.
      CLEAR p_file.
      IF screen-group1 EQ 'AA'.
        screen-active = '0'.
        MODIFY SCREEN.
      ENDIF.
    ENDIF.
  ENDLOOP.

AT SELECTION-SCREEN.
  CASE sy-ucomm.
    WHEN 'FC01'.
      zcl_abap_util=>download_mime(
        EXPORTING
          iv_url      = c_mime_obj
          iv_filename = CONV #( TEXT-l03 )
      ).
    WHEN 'ONLI' OR 'SJOB' OR 'PRIN'.
      IF p_file IS INITIAL AND r_up EQ abap_true.
        SET CURSOR FIELD 'P_FILE'.
        MESSAGE e055(00).
      ENDIF.


    WHEN OTHERS.
  ENDCASE.

AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_file.
  DATA it_files TYPE filetable.
  DATA rc TYPE i.
  DATA action TYPE i.

  cl_gui_frontend_services=>file_open_dialog(
    EXPORTING
      initial_directory       = dir
      file_filter             = |xlsx (*.xlsx)\|*.xlsx\|{ cl_gui_frontend_services=>filetype_all }|
    CHANGING
      file_table              = it_files
      rc                      = rc
      user_action             = action
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5 ##SUBRC_OK
  ).
  IF action = cl_gui_frontend_services=>action_ok.
    IF lines( it_files ) > 0.
      p_file = it_files[ 1 ]-filename.
    ENDIF.
  ENDIF.

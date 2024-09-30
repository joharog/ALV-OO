*&---------------------------------------------------------------------*
*&  Include           ZMM_CARGA_PED_COMPRA_F01
*&---------------------------------------------------------------------*

*---------------------------------------------------------------------
*            A T   S E L E C T I O N  -  S C R E E N
*---------------------------------------------------------------------
AT SELECTION-SCREEN ON VALUE-REQUEST FOR pfile.
  PERFORM get_filename CHANGING pfile.

*----------------------------------------------------------------------*
*            SUB - RUTINAS
*----------------------------------------------------------------------*
FORM get_filename CHANGING pfile.

  MOVE text-002 TO gs_title.
  REFRESH gti_file_table[].

  CALL METHOD cl_gui_frontend_services=>file_open_dialog
    EXPORTING
      window_title            = gs_title
      default_extension       = cl_gui_frontend_services=>filetype_excel
      file_filter             = '*.XLS*'
    CHANGING
      file_table              = gti_file_table
      rc                      = gi_rc
    EXCEPTIONS
      file_open_dialog_failed = 1
      cntl_error              = 2
      error_no_gui            = 3
      not_supported_by_gui    = 4
      OTHERS                  = 5.
  IF sy-subrc EQ 0.
    READ TABLE  gti_file_table INTO pfile INDEX 1.
    IF sy-subrc EQ 0.
      p_file = pfile.
    ENDIF.
  ELSE.
    MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
            WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
  ENDIF.

ENDFORM.                    "GET_FILENAME

*&---------------------------------------------------------------------*
*&      Form  GEN_PO
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM carga_po.

  DATA: resultado  TYPE esll-brtwr,
        ref_exc    TYPE REF TO cx_root,
        error      TYPE string,
        flag_catch TYPE char1,
        lv_catch   TYPE string.


  CALL METHOD obj_alv_grid->check_changed_data.

  DATA: data_tabix TYPE sy-tabix,
        item_tabix TYPE sy-tabix,
        serv_tabix TYPE sy-tabix.

  READ TABLE gt_data WITH KEY select = 'X' TRANSPORTING NO FIELDS.
  IF sy-subrc EQ 4.

    MESSAGE 'Debe selecionar al menos un registro' TYPE 'S' DISPLAY LIKE 'E'.

  ELSE.

    lt_serv[] = gt_data[].
    DELETE lt_serv WHERE doc_type NOT IN r_srv AND select NE 'X'.

    lt_impt[] = gt_data[].
    DELETE lt_impt WHERE select EQ ''.
    DELETE lt_impt WHERE serial_no EQ '00'.

    DATA: aux1 TYPE char1.

    LOOP AT gt_data INTO gs_data WHERE select EQ 'X' AND ex_item NE 'X'.

      data_tabix = sy-tabix.

      "Validar que posicion inicie con 10.
      IF gs_data-po_item EQ 10 AND lv_pos IS INITIAL.

        lv_pos = gs_data-po_item.
        flag_p = abap_true.

*        PERFORM fill_poheader.
*&---------------------------------------------------------------------*
*&                  P O H E A D E R
*&---------------------------------------------------------------------*

        IF gs_data-doc_type IS NOT INITIAL.
          t_poheader-doc_type  = gs_data-doc_type.
          t_poheaderx-doc_type = 'X'.
        ENDIF.

        IF gs_data-comp_code IS NOT INITIAL.
          t_poheader-comp_code  = gs_data-comp_code.
          t_poheaderx-comp_code = 'X'.
        ENDIF.

        IF gs_data-purch_org IS NOT INITIAL.
          t_poheader-purch_org  = gs_data-purch_org.
          t_poheaderx-purch_org = 'X'.
        ENDIF.

        IF gs_data-pur_group IS NOT INITIAL.
          t_poheader-pur_group  = gs_data-pur_group.
          t_poheaderx-pur_group = 'X'.
        ENDIF.

        IF gs_data-vendor IS NOT INITIAL.
          t_poheader-vendor  = gs_data-vendor.
          t_poheaderx-vendor = 'X'.
        ENDIF.

        IF gs_data-doc_date IS NOT INITIAL.
          t_poheader-doc_date  = gs_data-doc_date.
          t_poheaderx-doc_date = 'X'.
        ENDIF.

        IF gs_data-pmnttrms IS NOT INITIAL.
          t_poheader-pmnttrms = gs_data-pmnttrms.
          t_poheaderx-pmnttrms = 'X'.
        ENDIF.

        IF gs_data-currency IS NOT INITIAL.
          t_poheader-currency  = gs_data-currency.
          t_poheaderx-currency = 'X'.
        ENDIF.

        IF gs_data-exch_rate IS NOT INITIAL.
          t_poheader-exch_rate  = gs_data-exch_rate.
          t_poheaderx-exch_rate = 'X'.
        ENDIF.

        IF gs_data-ex_rate_fx IS NOT INITIAL.
          t_poheader-ex_rate_fx  = gs_data-ex_rate_fx.
          t_poheaderx-ex_rate_fx = 'X'.
        ENDIF.

        IF gs_data-incoterms1 IS NOT INITIAL.
          t_poheader-incoterms1  = gs_data-incoterms1.
          t_poheaderx-incoterms1 = 'X'.
        ENDIF.

        IF gs_data-incoterms2 IS NOT INITIAL.
          t_poheader-incoterms2  = gs_data-incoterms2.
          t_poheaderx-incoterms2 = 'X'.
        ENDIF.

        IF gs_data-retention_type IS NOT INITIAL.
          t_poheader-retention_type  = gs_data-retention_type.
          t_poheaderx-retention_type = 'X'.
        ENDIF.

*        PERFORM fill_poaccount.

      ENDIF.



      "Loop by item
      LOOP AT gt_data ASSIGNING <fs_data> WHERE select EQ 'X' AND ex_item NE 'X'.

        item_tabix = sy-tabix.

        IF <fs_data>-po_item IS NOT INITIAL.

          IF flag_p EQ abap_true OR lv_pos NE <fs_data>-po_item.

            IF data_tabix EQ item_tabix.
              "DO NOTHING.
            ELSEIF data_tabix NE item_tabix.
              data_tabix = data_tabix + 1.
              IF data_tabix NE item_tabix.
                EXIT.
              ENDIF.
            ENDIF.

            "Borrar en la primera entrada y aplicamos exclusion de las procesadas
            <fs_data>-ex_item = abap_true.
            CLEAR: flag_p.


            IF <fs_data>-po_item IS NOT INITIAL.
*&---------------------------------------------------------------------*
*&      START            I M P U T A C I O N
*&---------------------------------------------------------------------*
              LOOP AT lt_impt ASSIGNING <fs_impt> WHERE ex_impt NE 'X' AND ex_item NE 'X'.

*                IF <fs_data>-po_item EQ <fs_impt>-po_item.
                IF <fs_data>-po_item IS NOT INITIAL AND <fs_impt>-po_item IS NOT INITIAL.

                  IF <fs_data>-serial_no EQ 00.

                    EXIT.

                  ELSE.

                    IF sy-tabix EQ 1.

                      PERFORM fill_poaccount.
                      <fs_impt>-ex_impt = abap_true.
                      IF <fs_data>-ex_item IS NOT INITIAL.
                        <fs_impt>-ex_item = abap_true.
                      ENDIF.

*                      lv_imp = <fs_impt>-serial_no.

                    ELSE.

*                      IF <fs_impt>-serial_no > lv_imp.

                      PERFORM fill_poaccount.
                      <fs_impt>-ex_impt = abap_true.
                      IF <fs_data>-ex_item IS NOT INITIAL.
                        <fs_impt>-ex_item = abap_true.
                      ENDIF.
*                        lv_imp = <fs_impt>-serial_no.

*                      ELSE.
*                <fs_impt>-ex_impt = abap_true.
*                        EXIT.
*                      ENDIF.

                    ENDIF.

                  ENDIF.

                ELSE.
                  EXIT.
                ENDIF.

              ENDLOOP.
*&---------------------------------------------------------------------*
*&      END            I M P U T A C I O N
*&---------------------------------------------------------------------*
            ENDIF.



*            PERFORM fill_poitem.
*&---------------------------------------------------------------------*
*&                  P O I T E M
*&---------------------------------------------------------------------*

            IF <fs_data>-acctasscat IS NOT INITIAL.
              w_poitem-acctasscat  = <fs_data>-acctasscat.
              w_poitemx-acctasscat = 'X'.
            ENDIF.

            IF <fs_data>-item_cat IS NOT INITIAL.
              w_poitem-item_cat  = <fs_data>-item_cat.
              w_poitemx-item_cat = 'X'.
            ENDIF.

            IF <fs_data>-po_item IS NOT INITIAL.
              w_poitem-po_item  = <fs_data>-po_item.
              w_poitemx-po_item = <fs_data>-po_item.
            ENDIF.

            IF <fs_data>-matl_group IS NOT INITIAL.
              w_poitem-matl_group  = <fs_data>-matl_group.
              w_poitemx-matl_group = 'X'.
            ENDIF.

            IF <fs_data>-material IS NOT INITIAL.
              w_poitem-material  = <fs_data>-material.
              w_poitemx-material = 'X'.

*              SELECT SINGLE meins INTO w_poitem-po_unit FROM mara WHERE matnr EQ w_poitem-material.
*              IF sy-subrc EQ 0.
*                w_poitemx-po_unit  = 'X'.
*              ENDIF.
              w_poitem-po_unit   = <fs_data>-po_unit.
              w_poitemx-po_unit  = 'X'.
            ENDIF.

            IF <fs_data>-short_text IS NOT INITIAL.
              w_poitem-short_text  = <fs_data>-short_text.
              w_poitemx-short_text = 'X'.
            ENDIF.

            IF <fs_data>-itm_quantity IS NOT INITIAL.
              w_poitem-quantity  = <fs_data>-itm_quantity.
              w_poitemx-quantity = 'X'.
            ENDIF.

            IF <fs_data>-net_price IS NOT INITIAL.
              w_poitem-net_price  = <fs_data>-net_price.
              w_poitemx-net_price = 'X'.
            ENDIF.

            IF <fs_data>-plant IS NOT INITIAL.
              w_poitem-plant  = <fs_data>-plant.
              w_poitemx-plant = 'X'.
            ENDIF.

            IF <fs_data>-stge_loc IS NOT INITIAL.
              w_poitem-stge_loc = <fs_data>-stge_loc.
              w_poitemx-stge_loc = 'X'.
            ENDIF.

            IF <fs_data>-preq_name IS NOT INITIAL.
              w_poitem-preq_name  = <fs_data>-preq_name.
              w_poitemx-preq_name = 'X'.
            ENDIF.

            IF <fs_data>-qual_insp IS NOT INITIAL.
              w_poitem-qual_insp  = <fs_data>-qual_insp.
              w_poitemx-qual_insp = 'X'.
            ENDIF.

            IF <fs_data>-tax_code IS NOT INITIAL.
              w_poitem-tax_code  = <fs_data>-tax_code.
              w_poitemx-tax_code = 'X'.
            ENDIF.

            IF <fs_data>-conf_ctrl IS NOT INITIAL.
              w_poitem-conf_ctrl  = <fs_data>-conf_ctrl.
              w_poitemx-conf_ctrl = 'X'.
            ENDIF.

            IF <fs_data>-agreement IS NOT INITIAL.

              CALL FUNCTION 'BAPI_CONTRACT_GETDETAIL'
                EXPORTING
                  purchasingdocument = <fs_data>-agreement
                  item_data          = 'X'
                TABLES
                  item               = t_citem.

              IF sy-subrc EQ 0.
                READ TABLE t_citem INTO w_citem WITH KEY material = <fs_data>-material.
                IF sy-subrc EQ 0.
                  w_poitem-agreement  = <fs_data>-agreement.
                  w_poitem-agmt_item  = w_citem-item_no.
                  w_poitemx-agreement = 'X'.
                  w_poitemx-agmt_item = 'X'.
                ENDIF.
              ENDIF.
            ENDIF.

            IF <fs_data>-price_unit IS NOT INITIAL.
              w_poitem-price_unit  = <fs_data>-price_unit.
              w_poitemx-price_unit = 'X'.
            ENDIF.

            IF <fs_data>-doc_type NE 'PSER' AND <fs_data>-doc_type NE 'SV'.
              APPEND w_poitem TO t_poitem.
              APPEND w_poitemx TO t_poitemx.
            ELSE.

            IF <fs_data>-po_unit IS NOT INITIAL.
              w_poitem-po_unit  = <fs_data>-po_unit.
              w_poitemx-po_unit = 'X'.
            ENDIF.

              w_poitem-pckg_no   = 0000000001.
              w_poitemx-pckg_no  = 'X'.
              w_poitemx-po_itemx = 'X'.
              APPEND w_poitem TO t_poitem.
              APPEND w_poitemx TO t_poitemx.
            ENDIF.


*            PERFORM fill_poschedule.
*&---------------------------------------------------------------------*
*&                  P O S C H E D U L E
*&---------------------------------------------------------------------*

            IF <fs_data>-delivery_date IS NOT INITIAL.

              w_poschedule-delivery_date  = <fs_data>-delivery_date.
              w_poschedulex-delivery_date = 'X'.

              IF <fs_data>-po_item IS NOT INITIAL.
                w_poschedule-po_item  = <fs_data>-po_item.
                w_poschedulex-po_item = <fs_data>-po_item.
              ENDIF.

              IF <fs_data>-itm_quantity IS NOT INITIAL.
                w_poschedule-quantity  = <fs_data>-itm_quantity.
                w_poschedulex-quantity = 'X'.
              ENDIF.

              APPEND w_poschedule TO t_poschedule.
              APPEND w_poschedulex TO t_poschedulex.

            ENDIF.

          ENDIF.

        ELSE.
          EXIT.
        ENDIF.

      ENDLOOP.

*&---------------------------------------------------------------------*
*&                  S E R V I C E S
*&---------------------------------------------------------------------*

      IF gs_data-doc_type EQ 'PSER' OR  gs_data-doc_type EQ 'SV'.

*        w_poitem-pckg_no   = 0000000001.
*        w_poitemx-pckg_no  = 'X'.
*        w_poitemx-po_itemx = 'X'.
*
*        APPEND w_poitem TO t_poitem.
*        APPEND w_poitemx TO t_poitemx.

*        PERFORM fill_poservices.
        LOOP AT lt_serv ASSIGNING <fs_serv> WHERE select EQ 'X' AND ex_serv NE 'X'.


          serv_tabix = sy-tabix.

*            IF item_tabix EQ serv_tabix.
*              "DO NOTHING.
*            ELSEIF item_tabix NE serv_tabix.
*              serv_tabix = serv_tabix + 1.
*              IF serv_tabix NE data_tabix.
*                EXIT.
*              ENDIF.
*            ENDIF.

*          IF gs_data-po_item EQ 10 AND lv_pos IS INITIAL.

*          IF <fs_serv>-ext_line EQ 10 AND lv_srv IS INITIAL.
          IF lv_srv NE <fs_serv>-ext_line AND <fs_serv>-ext_line IS NOT INITIAL.

            IF <fs_serv>-ext_line EQ 10 AND flag_s IS INITIAL.

              " First entry
              w_poservices-pckg_no    = 0000000001.
              w_poservices-line_no    = 0000000001.
              w_poservices-outl_level =	0.
              w_poservices-outl_ind   = 'X'.
              w_poservices-subpckg_no = 0000000002.

              APPEND w_poservices TO t_poservices.
              CLEAR w_poservices.

              flag_s = 'X'.
*              lv_srv = <fs_serv>-ext_line.

            ENDIF.


            IF flag_s EQ abap_true OR gs_data-po_item NE <fs_serv>-ext_line.

              "Borrar en la primera entrada y aplicamos exclusion de las procesadas
              <fs_serv>-ex_serv = abap_true.
              CLEAR flag_s.

              " Second entry
              IF <fs_serv>-ext_line IS NOT INITIAL.

                IF w_poservices-pckg_no IS NOT INITIAL AND w_poservices-line_no IS NOT INITIAL.
                  w_poservices-pckg_no    = w_poservices-pckg_no + 1.
                  w_poservices-line_no    = w_poservices-line_no + 1.
                ELSE.
                  w_poservices-pckg_no    = w_poservices-pckg_no + 2.
                  w_poservices-line_no    = w_poservices-line_no + 2.
                ENDIF.
                w_poservices-outl_level = 0.
                w_poservices-ext_line   = <fs_serv>-ext_line.
                w_poservices-service    = <fs_serv>-service.
                w_poservices-quantity   = <fs_serv>-srv_quantity.
                w_poservices-base_uom   = <fs_serv>-base_uom.
                w_poservices-gr_price   = <fs_serv>-gr_price.

                TRY.
                    resultado = w_poservices-gr_price * w_poservices-quantity.
                  CATCH cx_sy_arithmetic_overflow INTO ref_exc.
                    error = ref_exc->get_text( ).
                    flag_catch = abap_true.
                    lv_catch = 'Valor desbordado: Precio Neto = Cant.Servicio * Precio Bruto.'.
                ENDTRY.




                APPEND w_poservices TO t_poservices.
*                  CLEAR w_poservices.

                w_posrvaccessvalues-pckg_no    = 0000000002.
                IF w_posrvaccessvalues-line_no IS NOT INITIAL.
                  w_posrvaccessvalues-line_no    = w_posrvaccessvalues-line_no + 1.
                ELSE.
                  w_posrvaccessvalues-line_no    = w_posrvaccessvalues-line_no + 2.
                ENDIF.
                w_posrvaccessvalues-serno_line = 01.
                w_posrvaccessvalues-percentage = 100.
                w_posrvaccessvalues-serial_no  = w_posrvaccessvalues-serial_no + 1.

                APPEND w_posrvaccessvalues TO t_posrvaccessvalues.
*                  CLEAR w_posrvaccessvalues.

              ENDIF.

              lv_srv = <fs_serv>-ext_line.

            ELSE.
              EXIT.
            ENDIF.

          ENDIF.

        ENDLOOP.

      ENDIF.

*&---------------------------------------------------------------------*
*&                  E X E C U T E   B A P I
*&---------------------------------------------------------------------*

      IF gs_data-po_item IS INITIAL.
        " Transferir log al siguiente registro

        DATA: lv_aux TYPE string,
              lv_pox TYPE dzekkn.

        CLEAR: lv_aux, lv_pos.

        LOOP AT gt_data ASSIGNING <fs_data> WHERE select EQ 'X'.

          IF <fs_data>-ex_item EQ abap_true AND <fs_data>-log NE ''.

            lv_aux = <fs_data>-log.
            lv_pox = <fs_data>-serial_no.

          ENDIF.

          IF <fs_data>-serial_no > lv_pox.

            <fs_data>-log = lv_aux.

            lv_pox = <fs_data>-serial_no.

          ENDIF.

        ENDLOOP.

      ELSE.


        IF flag_catch EQ abap_true.

          LOOP AT gt_data ASSIGNING <fs_data> WHERE ex_item EQ 'X' AND log EQ ''.
            MOVE lv_catch TO <fs_data>-log.
            MOVE '' TO <fs_data>-select.
            MOVE gc_red TO <fs_data>-status.
            ls_stylerow-fieldname = 'SELECT'.
            ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
            IF <fs_data>-field_style IS INITIAL.
              APPEND ls_stylerow  TO <fs_data>-field_style.
            ENDIF.
          ENDLOOP.

          CLEAR: flag_catch, lv_catch.

        ELSE.

          CALL FUNCTION 'BAPI_PO_CREATE1'
            EXPORTING
              poheader         = t_poheader
              poheaderx        = t_poheaderx
*          no_price_from_po = 'X'
            TABLES
              return            = t_return_bapi
              poitem            = t_poitem
              poitemx           = t_poitemx
              poaccount         = t_poaccount
              poaccountx        = t_poaccountx
              poschedule        = t_poschedule
              poschedulex       = t_poschedulex
              poservices        = t_poservices
              posrvaccessvalues = t_posrvaccessvalues.

        ENDIF.

        READ TABLE t_return_bapi INTO w_return_bapi  WITH KEY type = 'S' id = '06' number = '017'.
        IF sy-subrc EQ 0.

          COMMIT WORK AND WAIT.
          CALL FUNCTION 'DEQUEUE_ALL'.

          LOOP AT gt_data ASSIGNING <fs_data> WHERE ex_item EQ 'X' AND log EQ ''.
            MOVE w_return_bapi-message TO <fs_data>-log.
            MOVE '' TO <fs_data>-select.
            ls_stylerow-fieldname = 'SELECT'.
            ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
            IF <fs_data>-field_style IS INITIAL.
              APPEND ls_stylerow  TO <fs_data>-field_style.
            ENDIF.

          ENDLOOP.

          PERFORM clear_all.

        ELSE.

          DATA: copy_return TYPE bapiret2.
          DELETE t_return_bapi WHERE type NE 'E'.

          LOOP AT t_return_bapi INTO w_return_bapi WHERE type = 'E'.
            MOVE-CORRESPONDING w_return_bapi TO copy_return.

            AT LAST.
              LOOP AT gt_data ASSIGNING <fs_data> WHERE ex_item EQ 'X' AND log EQ ''.
                MOVE copy_return-message TO <fs_data>-log.
                MOVE '' TO <fs_data>-select.
                MOVE gc_red TO <fs_data>-status.
                ls_stylerow-fieldname = 'SELECT'.
                ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
                IF <fs_data>-field_style IS INITIAL.
                  APPEND ls_stylerow  TO <fs_data>-field_style.
                ENDIF.

              ENDLOOP.
              COMMIT WORK AND WAIT.
              CALL FUNCTION 'DEQUEUE_ALL'.

*              <fs_data>-log = copy_return-message.
            ENDAT.

*            IF w_return_bapi-id EQ 'MEPO' AND w_return_bapi-number EQ 000 OR w_return_bapi-id EQ 'BAPI' AND w_return_bapi-number EQ 001.
*            ELSE.
*              CONCATENATE <fs_data>-log w_return_bapi-message INTO <fs_data>-log SEPARATED BY space.
*            ENDIF.
          ENDLOOP.

          PERFORM clear_all.

        ENDIF. "end read table bapi return.

      ENDIF. "end po-item next log

    ENDLOOP. "end initial loop with real selected items

  ENDIF.  "end read table if selected items

ENDFORM.                    " GEN_PO
*&---------------------------------------------------------------------*
*&      Form  CHECK_MDATA
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM check_mdata.

  DATA:
        lt_marc TYPE TABLE OF marc,
        ls_marc TYPE marc,
        lt_mard TYPE TABLE OF mard,
        ls_mard TYPE mard,
        lt_mbew TYPE TABLE OF mbew,
        ls_mbew TYPE mbew.

  DATA:
        lv_tabix TYPE c.

  SELECT * FROM marc INTO TABLE lt_marc
    FOR ALL ENTRIES IN gt_data
      WHERE matnr EQ gt_data-material
        AND werks EQ gt_data-plant.

  SELECT * FROM mard INTO TABLE lt_mard
    FOR ALL ENTRIES IN gt_data
      WHERE matnr EQ gt_data-material
        AND werks EQ gt_data-plant
        AND lgort EQ gt_data-stge_loc.

*  SELECT * FROM mbew INTO TABLE lt_mbew
*    FOR ALL ENTRIES IN gt_data
*      WHERE matnr EQ gt_data-material
*        AND bwkey EQ gt_data-plant.


  LOOP AT gt_data ASSIGNING <gfs_data>.

    lv_tabix = sy-tabix.

    IF <gfs_data>-doc_type EQ 'PSER' OR <gfs_data>-doc_type EQ 'SV'. "Servicio

      <gfs_data>-status = gc_green. "icon_green_light.

    ELSE.

      READ TABLE lt_marc INTO ls_marc WITH KEY matnr = <gfs_data>-material werks = <gfs_data>-plant.
      IF sy-subrc EQ 0.
        <gfs_data>-status = gc_green. "icon_green_light.

*        READ TABLE lt_mard INTO ls_mard WITH KEY matnr = <gfs_data>-material werks = <gfs_data>-plant lgort = <gfs_data>-stge_loc.
*        IF sy-subrc EQ 0.
*          <gfs_data>-status = gc_green. "icon_green_light.
*        ELSE.
*          <gfs_data>-status = gc_red.
*          ls_stylerow-fieldname = 'SELECT'.
*          ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
*          IF <gfs_data>-field_style IS INITIAL.
*            APPEND ls_stylerow  TO <gfs_data>-field_style.
*          ENDIF.
*          CONCATENATE 'Material' <gfs_data>-material 'no existe en almacen' <gfs_data>-stge_loc INTO <gfs_data>-log SEPARATED BY space.
*          CONTINUE.
*        ENDIF.

      ELSE.
        <gfs_data>-status = gc_red.
        ls_stylerow-fieldname = 'SELECT'.
        ls_stylerow-style = cl_gui_alv_grid=>mc_style_disabled.
        IF <gfs_data>-field_style IS INITIAL.
          APPEND ls_stylerow  TO <gfs_data>-field_style.
        ENDIF.
        CONCATENATE 'Material' <gfs_data>-material 'no existe en centro' <gfs_data>-plant INTO <gfs_data>-log SEPARATED BY space.
        CONTINUE.
      ENDIF.

    ENDIF.


  ENDLOOP.

ENDFORM.                    " CHECK_MDATA
*&---------------------------------------------------------------------*
*&      Form  GET_ITAB
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM get_itab .

*Populate data to internal tables and structures
  SORT gt_excel BY row col.

  DATA: lv_value TYPE char255.
  DATA: lr_cxroot TYPE REF TO cx_root,
        msg TYPE string.

  LOOP AT gt_excel INTO gs_excel.

    TRY.
        CASE gs_excel-col.
          WHEN 1.gs_data-doc_type        = gs_excel-value.
          WHEN 2.gs_data-comp_code       = gs_excel-value.
          WHEN 3.gs_data-purch_org       = gs_excel-value.
          WHEN 4.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-pur_group.
          WHEN 5.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-vendor.
          WHEN 6.
            CALL FUNCTION 'CONVERSION_EXIT_PDATE_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-doc_date.
          WHEN 7.gs_data-pmnttrms        = gs_excel-value.
          WHEN 8.gs_data-currency        = gs_excel-value.
          WHEN 9.gs_data-exch_rate       = gs_excel-value.
          WHEN 10. gs_data-ex_rate_fx     = gs_excel-value.
          WHEN 11. gs_data-incoterms1     = gs_excel-value.
          WHEN 12. gs_data-incoterms2     = gs_excel-value.
          WHEN 13. gs_data-temp1          = gs_excel-value.
          WHEN 14. gs_data-temp2          = gs_excel-value.
          WHEN 15. gs_data-retention_type = gs_excel-value.
          WHEN 16. gs_data-acctasscat     = gs_excel-value.
          WHEN 17. gs_data-item_cat       = gs_excel-value.
          WHEN 18. gs_data-po_item        = gs_excel-value.
          WHEN 19. gs_data-matl_group     = gs_excel-value.
          WHEN 20.
            CALL FUNCTION 'CONVERSION_EXIT_MATN1_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-material.
          WHEN 21. gs_data-short_text     = gs_excel-value.
          WHEN 22. gs_data-itm_quantity   = gs_excel-value.
          WHEN 23. gs_data-po_unit        = gs_excel-value.
          WHEN 24. gs_data-net_price      = gs_excel-value.
          WHEN 25. gs_data-plant          = gs_excel-value.
          WHEN 26. gs_data-stge_loc       = gs_excel-value.
          WHEN 27. gs_data-preq_name      = gs_excel-value.
          WHEN 28. gs_data-qual_insp      = gs_excel-value.
          WHEN 29. gs_data-tax_code       = gs_excel-value.
          WHEN 30. gs_data-temp3          = gs_excel-value.
          WHEN 31. gs_data-temp4          = gs_excel-value.
          WHEN 32. gs_data-conf_ctrl      = gs_excel-value.
          WHEN 33. gs_data-delivery_date  = gs_excel-value.
          WHEN 34. gs_data-price_unit     = gs_excel-value.
          WHEN 35. gs_data-agreement      = gs_excel-value.
*            CALL FUNCTION 'CONVERSION_EXIT_PDATE_INPUT'
*              EXPORTING
*                input  = gs_excel-value
*              IMPORTING
*                output = gs_data-delivery_date.
          WHEN 36. gs_data-ext_line       = gs_excel-value.
          WHEN 37.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-service.
          WHEN 38. gs_data-srv_quantity   = gs_excel-value.
          WHEN 39. gs_data-base_uom       = gs_excel-value.
          WHEN 40. gs_data-gr_price       = gs_excel-value.
*          WHEN 34.
*            WRITE gs_excel-value TO lv_value.
*            MOVE lv_value TO  gs_data-gr_price.
          WHEN 41. gs_data-serial_no      = gs_excel-value.
          WHEN 42. gs_data-distr_perc     = gs_excel-value.
          WHEN 43. gs_data-part_inv       = gs_excel-value.
          WHEN 44. gs_data-imp_quantity   = gs_excel-value.
          WHEN 45.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-costcenter.
          WHEN 46.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-gl_account.
          WHEN 47.
            CALL FUNCTION 'CONVERSION_EXIT_ALPHA_INPUT'
              EXPORTING
                input  = gs_excel-value
              IMPORTING
                output = gs_data-orderid.
        ENDCASE.

        AT END OF row.
          APPEND gs_data TO gt_data.
          CLEAR gs_data.
        ENDAT.

      CATCH cx_sy_conversion_overflow INTO lr_cxroot.
        msg = lr_cxroot->get_text( ).
        MESSAGE msg TYPE 'I'.
    ENDTRY.

  ENDLOOP.

ENDFORM.                    " GET_ITAB
*&---------------------------------------------------------------------*
*&      Form  CLEAR_ALL
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM clear_all .

  CLEAR:
         t_poheader,
         t_poheaderx,
         w_poitem,
         w_poitemx,
         w_poschedule,
         w_poschedulex,
         w_poaccount,
         w_poaccountx,
         w_poservices,
         w_posrvaccessvalues,
         w_return_bapi,
         lv_pos,
         lv_srv,
         lv_imp.

  REFRESH:
           t_poitem,
           t_poitemx,
           t_poschedule,
           t_poschedulex,
           t_poaccount,
           t_poaccountx,
           t_poservices,
           t_posrvaccessvalues,
           t_return_bapi.

ENDFORM.                    " CLEAR_ALL
*&---------------------------------------------------------------------*
*&      Form  FILL_POHEADER
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_poheader .

*&---------------------------------------------------------------------*
*&                  P O H E A D E R
*&---------------------------------------------------------------------*

  IF gs_data-doc_type IS NOT INITIAL.
    t_poheader-doc_type  = gs_data-doc_type.
    t_poheaderx-doc_type = 'X'.
  ENDIF.

  IF gs_data-comp_code IS NOT INITIAL.
    t_poheader-comp_code  = gs_data-comp_code.
    t_poheaderx-comp_code = 'X'.
  ENDIF.

  IF gs_data-purch_org IS NOT INITIAL.
    t_poheader-purch_org  = gs_data-purch_org.
    t_poheaderx-purch_org = 'X'.
  ENDIF.

  IF gs_data-pur_group IS NOT INITIAL.
    t_poheader-pur_group  = gs_data-pur_group.
    t_poheaderx-pur_group = 'X'.
  ENDIF.

  IF gs_data-vendor IS NOT INITIAL.
    t_poheader-vendor  = gs_data-vendor.
    t_poheaderx-vendor = 'X'.
  ENDIF.

  IF gs_data-doc_date IS NOT INITIAL.
    t_poheader-doc_date  = gs_data-doc_date.
    t_poheaderx-doc_date = 'X'.
  ENDIF.

  IF gs_data-pmnttrms IS NOT INITIAL.
    t_poheader-pmnttrms = gs_data-pmnttrms.
    t_poheaderx-pmnttrms = 'X'.
  ENDIF.

  IF gs_data-currency IS NOT INITIAL.
    t_poheader-currency  = gs_data-currency.
    t_poheaderx-currency = 'X'.
  ENDIF.

  IF gs_data-exch_rate IS NOT INITIAL.
    t_poheader-exch_rate  = gs_data-exch_rate.
    t_poheaderx-exch_rate = 'X'.
  ENDIF.

  IF gs_data-ex_rate_fx IS NOT INITIAL.
    t_poheader-ex_rate_fx  = gs_data-ex_rate_fx.
    t_poheaderx-ex_rate_fx = 'X'.
  ENDIF.

  IF gs_data-incoterms1 IS NOT INITIAL.
    t_poheader-incoterms1  = gs_data-incoterms1.
    t_poheaderx-incoterms1 = 'X'.
  ENDIF.

  IF gs_data-incoterms2 IS NOT INITIAL.
    t_poheader-incoterms2  = gs_data-incoterms2.
    t_poheaderx-incoterms2 = 'X'.
  ENDIF.

  IF gs_data-retention_type IS NOT INITIAL.
    t_poheader-retention_type  = gs_data-retention_type.
    t_poheaderx-retention_type = 'X'.
  ENDIF.

ENDFORM.                    " FILL_POHEADER
*&---------------------------------------------------------------------*
*&      Form  FILL_POITEM
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_poitem .

*&---------------------------------------------------------------------*
*&                  P O I T E M
*&---------------------------------------------------------------------*

  IF <fs_data>-acctasscat IS NOT INITIAL.
    w_poitem-acctasscat  = <fs_data>-acctasscat.
    w_poitemx-acctasscat = 'X'.
  ENDIF.

  IF <fs_data>-item_cat IS NOT INITIAL.
    w_poitem-item_cat  = <fs_data>-item_cat.
    w_poitemx-item_cat = 'X'.
  ENDIF.

  IF <fs_data>-po_item IS NOT INITIAL.
    w_poitem-po_item  = <fs_data>-po_item.
    w_poitemx-po_item = <fs_data>-po_item.
  ENDIF.

  IF <fs_data>-matl_group IS NOT INITIAL.
    w_poitem-matl_group  = <fs_data>-matl_group.
    w_poitemx-matl_group = 'X'.
  ENDIF.

  IF <fs_data>-material IS NOT INITIAL.
    w_poitem-material  = <fs_data>-material.
    w_poitemx-material = 'X'.

    SELECT SINGLE meins INTO w_poitem-po_unit FROM mara WHERE matnr EQ w_poitem-material.
    IF sy-subrc EQ 0.
      w_poitemx-po_unit  = 'X'.
    ENDIF.
  ENDIF.

  IF <fs_data>-short_text IS NOT INITIAL.
    w_poitem-short_text  = <fs_data>-short_text.
    w_poitemx-short_text = 'X'.
  ENDIF.

  IF <fs_data>-itm_quantity IS NOT INITIAL.
    w_poitem-quantity  = <fs_data>-itm_quantity.
    w_poitemx-quantity = 'X'.
  ENDIF.

  IF <fs_data>-po_unit IS NOT INITIAL.
    w_poitem-po_unit  = <fs_data>-po_unit.
    w_poitemx-po_unit = 'X'.
  ENDIF.

  IF <fs_data>-net_price IS NOT INITIAL.
    w_poitem-net_price  = <fs_data>-net_price.
    w_poitemx-net_price = 'X'.
  ENDIF.

  IF <fs_data>-plant IS NOT INITIAL.
    w_poitem-plant  = <fs_data>-plant.
    w_poitemx-plant = 'X'.
  ENDIF.

  IF <fs_data>-stge_loc IS NOT INITIAL.
    w_poitem-stge_loc = <fs_data>-stge_loc.
    w_poitemx-stge_loc = 'X'.
  ENDIF.

  IF <fs_data>-preq_name IS NOT INITIAL.
    w_poitem-preq_name  = <fs_data>-preq_name.
    w_poitemx-preq_name = 'X'.
  ENDIF.

  IF <fs_data>-qual_insp IS NOT INITIAL.
    w_poitem-qual_insp  = <fs_data>-qual_insp.
    w_poitemx-qual_insp = 'X'.
  ENDIF.

  IF <fs_data>-tax_code IS NOT INITIAL.
    w_poitem-tax_code  = <fs_data>-tax_code.
    w_poitemx-tax_code = 'X'.
  ENDIF.

  IF <fs_data>-conf_ctrl IS NOT INITIAL.
    w_poitem-conf_ctrl  = <fs_data>-conf_ctrl.
    w_poitemx-conf_ctrl = 'X'.
  ENDIF.

  IF <fs_data>-doc_type NE 'PSER' AND <fs_data>-doc_type NE 'SV'.
    APPEND w_poitem TO t_poitem.
    APPEND w_poitemx TO t_poitemx.
  ENDIF.

ENDFORM.                    " FILL_POITEM
*&---------------------------------------------------------------------*
*&      Form  FILL_POSCHEDULE
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_poschedule .

*&---------------------------------------------------------------------*
*&                  P O S C H E D U L E
*&---------------------------------------------------------------------*

  IF <fs_data>-delivery_date IS NOT INITIAL.

    w_poschedule-delivery_date  = <fs_data>-delivery_date.
    w_poschedulex-delivery_date = 'X'.

    IF <fs_data>-po_item IS NOT INITIAL.
      w_poschedule-po_item  = <fs_data>-po_item.
      w_poschedulex-po_item = <fs_data>-po_item.
    ENDIF.

    IF <fs_data>-itm_quantity IS NOT INITIAL.
      w_poschedule-quantity  = <fs_data>-itm_quantity.
      w_poschedulex-quantity = 'X'.
    ENDIF.

    APPEND w_poschedule TO t_poschedule.
    APPEND w_poschedulex TO t_poschedulex.

  ENDIF.

ENDFORM.                    " FILL_POSCHEDULE
*&---------------------------------------------------------------------*
*&      Form  FILL_POACCOUNT
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_poaccount .

  IF <fs_impt>-po_item IS NOT INITIAL.
    w_poaccount-po_item   = <fs_impt>-po_item.
    w_poaccountx-po_item  = <fs_impt>-po_item.
  ELSE.
    w_poaccount-po_item   = w_poaccount-po_item.
    w_poaccountx-po_item  = w_poaccountx-po_item.
  ENDIF.

  IF w_poaccount-po_item IS NOT INITIAL.
    w_poaccount-serial_no   = <fs_impt>-serial_no. "w_poaccount-serial_no + 1.
    w_poaccountx-serial_no  = <fs_impt>-serial_no. "w_poaccountx-serial_no + 1.
    w_poaccountx-serial_nox = 'X'.
    w_poaccountx-po_itemx   = 'X'.
  ENDIF.

  IF <fs_impt>-distr_perc IS NOT INITIAL.
    w_poaccount-distr_perc = <fs_impt>-distr_perc.
    w_poaccountx-distr_perc = 'X'.
  ENDIF.

  IF <fs_impt>-imp_quantity IS NOT INITIAL.
    w_poaccount-quantity   = <fs_impt>-imp_quantity.
    w_poaccountx-quantity   = 'X'.
  ENDIF.

  IF <fs_impt>-costcenter IS NOT INITIAL.
    w_poaccount-costcenter = <fs_impt>-costcenter.
    w_poaccountx-costcenter = 'X'.
  ENDIF.

  IF <fs_impt>-gl_account IS NOT INITIAL.
    w_poaccount-gl_account = <fs_impt>-gl_account.
    w_poaccountx-gl_account = 'X'.
  ENDIF.


  IF <fs_impt>-orderid IS NOT INITIAL.
    w_poaccount-orderid = <fs_impt>-orderid.
    w_poaccountx-orderid = 'X'.
  ENDIF.

  APPEND w_poaccount TO t_poaccount.
  APPEND w_poaccountx TO t_poaccountx.


ENDFORM.                    " FILL_POACCOUNT
*&---------------------------------------------------------------------*
*&      Form  FILL_POSERVICES
*&---------------------------------------------------------------------*
*       text
*----------------------------------------------------------------------*
*  -->  p1        text
*  <--  p2        text
*----------------------------------------------------------------------*
FORM fill_poservices .

  LOOP AT lt_serv ASSIGNING <fs_serv> WHERE select EQ 'X' AND ex_serv NE 'X'.

    IF <fs_serv>-ext_line EQ 10 AND flag_s IS INITIAL.

      " First entry
      w_poservices-pckg_no    = 0000000001.
      w_poservices-line_no    = 0000000001.
      w_poservices-outl_level =	0.
      w_poservices-outl_ind   = 'X'.
      w_poservices-subpckg_no = 0000000002.

      APPEND w_poservices TO t_poservices.
      CLEAR w_poservices.
      flag_s = 'X'.

    ENDIF.

    IF flag_s EQ abap_true OR <fs_data>-po_item NE <fs_serv>-ext_line.

      "Borrar en la primera entrada y aplicamos exclusion de las procesadas
      <fs_data>-ex_serv = abap_true.
      CLEAR flag_s.

      " Second entry
      IF <fs_serv>-ext_line IS NOT INITIAL.

        IF w_poservices-pckg_no IS NOT INITIAL AND w_poservices-line_no IS NOT INITIAL.
          w_poservices-pckg_no    = w_poservices-pckg_no + 1.
          w_poservices-line_no    = w_poservices-line_no + 1.
        ELSE.
          w_poservices-pckg_no    = w_poservices-pckg_no + 2.
          w_poservices-line_no    = w_poservices-line_no + 2.
        ENDIF.
        w_poservices-outl_level = 0.
        w_poservices-ext_line   = <fs_serv>-ext_line.
        w_poservices-service    = <fs_serv>-service.
        w_poservices-quantity   = <fs_serv>-srv_quantity.
        w_poservices-base_uom   = <fs_serv>-base_uom.
        w_poservices-gr_price   = <fs_serv>-gr_price.

        APPEND w_poservices TO t_poservices.
*                  CLEAR w_poservices.

        w_posrvaccessvalues-pckg_no    = 0000000002.
        IF w_posrvaccessvalues-line_no IS NOT INITIAL.
          w_posrvaccessvalues-line_no    = w_posrvaccessvalues-line_no + 1.
        ELSE.
          w_posrvaccessvalues-line_no    = w_posrvaccessvalues-line_no + 2.
        ENDIF.
        w_posrvaccessvalues-serno_line = 01.
        w_posrvaccessvalues-percentage = 100.
        w_posrvaccessvalues-serial_no  = w_posrvaccessvalues-serial_no + 1.

        APPEND w_posrvaccessvalues TO t_posrvaccessvalues.
*                  CLEAR w_posrvaccessvalues.

      ENDIF.

    ELSE.
      EXIT.
    ENDIF.

  ENDLOOP.

ENDFORM.                    " FILL_POSERVICES

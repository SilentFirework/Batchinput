*&---------------------------------------------------------------------*
*&  °üº¬                ZREV_UPLOAD_PLAN_CLASS
*&---------------------------------------------------------------------*
*-----------------------------------------------------------------------
* class lcl_file  DEFINITION
*-----------------------------------------------------------------------
CLASS lcl_file DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES: BEGIN OF ts_value_data,
             name     TYPE soi_field_name,
             valuetab TYPE soi_generic_table,
           END OF ts_value_data.

    DATA: mv_desktop     TYPE string."desktop
    DATA: mv_down_path   TYPE string."download path
    DATA: mv_upload_path TYPE rlgrap-filename."upload path
    DATA: mt_data        TYPE TABLE OF ts_value_data."uploaded data
    DATA: mt_head        TYPE TABLE OF ts_value_data."the header for uploaded data

    CONSTANTS: BEGIN OF c_s_wwwdatatab,"smw0
                 relid TYPE wwwdatatab-relid VALUE 'MI',
                 objid TYPE wwwdatatab-objid VALUE '',
               END OF c_s_wwwdatatab.

    CONSTANTS c_rows TYPE i VALUE '1000'."row
    CONSTANTS c_cols TYPE i VALUE '30'.  "col

    METHODS get_desk_top.

    METHODS open_select_dialog_upload
      EXPORTING
        ev_user_action TYPE i."user action

    METHODS open_select_dialog_save
      EXPORTING
        ev_user_action TYPE i."user action

    METHODS download_template.

    METHODS upload_data
      EXPORTING
        es_message TYPE lrm_s_t100_message."message

ENDCLASS.
*&------------------------------------------------------------------------------------------- &*
*& class lcl_file  IMPLEMENTATION                                                             &*
*&------------------------------------------------------------------------------------------- &*
CLASS lcl_file IMPLEMENTATION.
*&---------------------------------------------------------------------*
*&  get_desk_top  get desktop
*&---------------------------------------------------------------------*
  METHOD get_desk_top."

*&------------Find desktop
    CALL METHOD cl_gui_frontend_services=>get_desktop_directory
      CHANGING
        desktop_directory    = mv_desktop
      EXCEPTIONS
        cntl_error           = 1
        error_no_gui         = 2
        not_supported_by_gui = 3
        OTHERS               = 4.

*&------------update the view of the control
    CALL METHOD cl_gui_cfw=>update_view
      EXCEPTIONS
        cntl_system_error = 1
        cntl_error        = 2
        OTHERS            = 3.
    IF mv_desktop IS INITIAL.
      mv_desktop = 'C:/' .
    ENDIF.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  open_select_dialog_upload ´ò¿ªÉÏ´«ÎÄ¼þÑ¡Ôñ´°¿Ú
*&---------------------------------------------------------------------*
  METHOD open_select_dialog_upload."
    DATA: lt_i_files     TYPE filetable,
          ls_wa_files    TYPE file_table,
          lv_user_action TYPE int4,
          lv_rc          TYPE int4.
    DATA: lv_window_title TYPE string.
*&-------------Show open file dialog box
    lv_window_title = 'please select excel file'(t03).

    CALL METHOD cl_gui_frontend_services=>file_open_dialog
      EXPORTING
        window_title            = lv_window_title
        default_extension       = '.xlsx'
        file_filter             = 'Excel File,(*.xlsx)|*.xlsx;*.xls|Excel 2003 file,(*.xls)|*.xls|'
        initial_directory       = mv_desktop
        multiselection          = abap_false
      CHANGING
        file_table              = lt_i_files
        rc                      = lv_rc
        user_action             = lv_user_action
      EXCEPTIONS
        file_open_dialog_failed = 1
        cntl_error              = 2
        error_no_gui            = 3
        not_supported_by_gui    = 4
        OTHERS                  = 5.

    READ TABLE lt_i_files INDEX 1 INTO ls_wa_files.
    IF sy-subrc = 0 AND lv_rc = 1.
      mv_upload_path = ls_wa_files-filename.
    ELSEIF lv_rc = -1.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ENDIF.

    ev_user_action = lv_user_action.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  open_select_dialog_save
*&---------------------------------------------------------------------*
  METHOD open_select_dialog_save.

    DATA: lv_default_file_name   TYPE string.
    DATA: lv_window_title        TYPE string.
    DATA: lv_user_action         TYPE i.
    DATA: lv_path                TYPE string."Â·¾¶

    lv_window_title      = 'Please select the folder to save template'(t01).
    lv_default_file_name = 'Template'(t02).

*&------´ò¿ª±£´æµÄÑ¡ÔñÂ·¾¶´°¿Ú
    cl_gui_frontend_services=>file_save_dialog(
       EXPORTING
         window_title             = lv_window_title
         default_extension        = '.xlsx'
         default_file_name        = lv_default_file_name
         file_filter              = 'Excel File,(*.xlsx)|*.xlsx;*.xls|Excel 2003 file,(*.xls)|*.xls|'
         initial_directory        = mv_desktop
         prompt_on_overwrite      = 'X'
      CHANGING
        path                      = lv_path
        fullpath                  = mv_down_path
        filename                  = lv_default_file_name
        user_action               = lv_user_action
       EXCEPTIONS
         cntl_error                = 1
         error_no_gui              = 2
         not_supported_by_gui      = 3
         invalid_default_file_name = 4
         OTHERS                    = 5
           ).
    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE sy-msgty NUMBER sy-msgno
        WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
    ELSE.
      ev_user_action = lv_user_action.
    ENDIF.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  download_template
*&---------------------------------------------------------------------*
  METHOD download_template.

    DATA: ls_objdata     TYPE wwwdatatab,
          lv_destination TYPE rlgrap-filename,
          lv_rc          TYPE sy-subrc.

*&------check the template whether is exist
    SELECT SINGLE relid objid
      FROM wwwdata
      INTO CORRESPONDING FIELDS OF ls_objdata
      WHERE srtf2 = 0
      AND relid = c_s_wwwdatatab-relid
      AND objid = c_s_wwwdatatab-objid.

    IF sy-subrc NE 0 OR ls_objdata-objid = ' '.
      MESSAGE e096.
    ENDIF.

*&------path
    lv_destination = mv_down_path.
    TRANSLATE lv_destination TO UPPER CASE.

*&------download
    CALL FUNCTION 'DOWNLOAD_WEB_OBJECT'
      EXPORTING
        key         = ls_objdata
        destination = lv_destination
      IMPORTING
        rc          = lv_rc.
    IF lv_rc NE 0.
      MESSAGE s096 DISPLAY LIKE 'E'.
    ENDIF.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  upload_data
*&---------------------------------------------------------------------*
  METHOD upload_data.

    DATA: lo_container   TYPE REF TO cl_gui_custom_container,
          lo_control     TYPE REF TO i_oi_container_control,
          lo_document    TYPE REF TO i_oi_document_proxy,
          lo_spreadsheet TYPE REF TO i_oi_spreadsheet,
          lo_error       TYPE REF TO i_oi_error.

    DATA: lv_document_url TYPE c LENGTH 256,
          lt_sheets       TYPE soi_sheets_table,
          ls_sheets       TYPE soi_sheets,
          lt_data         TYPE soi_generic_table,
          lt_head         TYPE soi_generic_table,
          ls_data         TYPE soi_generic_item,
          lt_ranges       TYPE soi_range_list,
          ls_value_data   TYPE ts_value_data.

    FIELD-SYMBOLS: <lv_field> TYPE any.

*&------get container
    CALL METHOD c_oi_container_control_creator=>get_container_control
      IMPORTING
        control = lo_control
        error   = lo_error
*       retcode =
      .
    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'E'.
    ENDIF.

*&------initial container
    CREATE OBJECT lo_container
      EXPORTING
*       parent                      =
        container_name              = 'CONTAINER'
*       style                       =
*       lifetime                    = lifetime_default
*       repid                       =
*       dynnr                       =
*       no_autodef_progid_dynnr     =
      EXCEPTIONS
        cntl_error                  = 1
        cntl_system_error           = 2
        create_error                = 3
        lifetime_error              = 4
        lifetime_dynpro_dynpro_link = 5
        OTHERS                      = 6.
    IF sy-subrc <> 0.
      MESSAGE e001(00) WITH 'Error while creating container'.
    ENDIF.

*&------intial controll
    CALL METHOD lo_control->init_control
      EXPORTING
*       dynpro_nr            = SY-DYNNR
*       gui_container        = ' '
        inplace_enabled      = 'X'
*       inplace_mode         = 0
*       inplace_resize_documents = ' '
*       inplace_scroll_documents = ' '
*       inplace_show_toolbars    = 'X'
*       no_flush             = ' '
*       parent_id            = cl_gui_cfw=>dynpro_0
        r3_application_name  = 'EXCEL CONTAINER'
*       register_on_close_event  = ' '
*       register_on_custom_event = ' '
*       rep_id               = SY-REPID
*       shell_style          = 1384185856
        parent               = lo_container
*       name                 =
*       autoalign            = 'x'
      IMPORTING
        error                = lo_error
*       retcode              =
      EXCEPTIONS
        javabeannotsupported = 1
        OTHERS               = 2.
    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'E'.
    ENDIF.

*&------get document object
    CALL METHOD lo_control->get_document_proxy
      EXPORTING
*       document_format    = 'NATIVE'
        document_type  = soi_doctype_excel_sheet
*       no_flush       = ' '
*       register_container = ' '
      IMPORTING
        document_proxy = lo_document
        error          = lo_error
*       retcode        =
      .
    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'E'.
    ENDIF.

    CONCATENATE 'FILE://' mv_upload_path INTO lv_document_url.

*&------open file
    CALL METHOD lo_document->open_document
      EXPORTING
        document_title = 'Excel'
        document_url   = lv_document_url
        open_inplace   = 'X'
        open_readonly  = abap_true
*       protect_document = ' '
*       onsave_macro   = ' '
*       startup_macro  = ''
*       user_info      =
      IMPORTING
        error          = lo_error
*       retcode        =
      .
    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'I'.
      LEAVE LIST-PROCESSING.
    ENDIF.

*&------get sheet in excel
    CALL METHOD lo_document->get_spreadsheet_interface
      EXPORTING
        no_flush        = ' '
      IMPORTING
        error           = lo_error
        sheet_interface = lo_spreadsheet
*       retcode         =
      .

    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'I'.
      LEAVE LIST-PROCESSING.
    ENDIF.

*&------get data in sheet
    CALL METHOD lo_spreadsheet->get_sheets
      EXPORTING
        no_flush = ' '
*       updating = -1
      IMPORTING
        sheets   = lt_sheets
        error    = lo_error
*       retcode  =
      .

    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'I'.
      LEAVE LIST-PROCESSING.
    ENDIF.

*&------multiple sheets
    LOOP AT lt_sheets INTO ls_sheets.
      CALL METHOD lo_spreadsheet->select_sheet
        EXPORTING
          name  = ls_sheets-sheet_name
*         no_flush = ' '
        IMPORTING
          error = lo_error
*         retcode  =
        .
      IF lo_error->has_failed = 'X'.
        EXIT.
        CALL METHOD lo_error->raise_message
          EXPORTING
            type = 'E'.
      ENDIF.

*&------set data range
      CALL METHOD lo_spreadsheet->set_selection
        EXPORTING
          top     = 2
          left    = 1
          rows    = c_rows
          columns = c_cols.

      CALL METHOD lo_spreadsheet->insert_range
        EXPORTING
          name     = ls_sheets-sheet_name
          rows     = c_rows
          columns  = c_cols
          no_flush = ''
        IMPORTING
          error    = lo_error.
      IF lo_error->has_failed = 'X'.
        EXIT.
        CALL METHOD lo_error->raise_message
          EXPORTING
            type = 'E'.
      ENDIF.

      CLEAR:lt_head, lt_data.

*&------get data in range
      CALL METHOD lo_spreadsheet->get_ranges_data
        EXPORTING
*         no_flush = ' '
          all      = 'X'
*         updating = -1
*         rangesdef =
        IMPORTING
          contents = lt_data
          error    = lo_error
*         retcode  =
        CHANGING
          ranges   = lt_ranges.
* Remove ranges not to be processed else the data keeps on adding up
      CALL METHOD lo_spreadsheet->delete_ranges
        EXPORTING
          ranges = lt_ranges.
      DELETE lt_data WHERE value IS INITIAL OR value = space.

*&------set the header in the excel
      lt_head = lt_data.
      DELETE lt_head WHERE row <> 1.
      ls_value_data-name     = ls_sheets-sheet_name.
      ls_value_data-valuetab = lt_head.
      APPEND ls_value_data TO mt_head.

*&------data in file
      DELETE lt_data WHERE row = 1.
      ls_value_data-name     = ls_sheets-sheet_name.
      ls_value_data-valuetab = lt_data.
      APPEND ls_value_data TO mt_data.

    ENDLOOP.

    CALL METHOD lo_document->close_document
*  EXPORTING
*    do_save     = ' '
*    no_flush    = ' '
      IMPORTING
        error = lo_error
*       has_changed =
*       retcode     =
      .
    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'I'.
      LEAVE LIST-PROCESSING.
    ENDIF.
    CALL METHOD lo_document->release_document
*  EXPORTING
*    no_flush = ' '
      IMPORTING
        error = lo_error
*       retcode  =
      .
    IF lo_error->has_failed = 'X'.
      CALL METHOD lo_error->raise_message
        EXPORTING
          type = 'I'.
      LEAVE LIST-PROCESSING.
    ENDIF.
  ENDMETHOD.

ENDCLASS.
*&------------------------------------------------------------------------------------------- &*
*& class lcl_ddic_object  DEFINITION                                                          &*
*&------------------------------------------------------------------------------------------- &*
CLASS lcl_ddic_object DEFINITION FINAL.

  PUBLIC SECTION.

    TYPES: tt_value_data TYPE TABLE OF lcl_file=>ts_value_data.

*&------table
    DATA: mt_dd02v TYPE TABLE OF dd02v,
          mt_dd09l TYPE TABLE OF dd09l,
          mt_dd03p TYPE TABLE OF dd03p.

*&------data exement
    DATA: mt_dd04v TYPE TABLE OF dd04v.

*&------domain
    DATA: mt_dd01v TYPE TABLE OF dd01v,
          mt_dd07v TYPE TABLE OF dd07v.

*&------message
    TYPES: BEGIN OF ts_error_message.
        INCLUDE TYPE dwinactiv.
    TYPES: message TYPE string.
    TYPES END OF ts_error_message.

    DATA: mt_act_object   TYPE TABLE OF dwinactiv."created object

    DATA: mt_error_object TYPE TABLE OF ts_error_message."error object

    DATA: mt_data        TYPE TABLE OF lcl_file=>ts_value_data."upload data
    DATA: mt_head        TYPE TABLE OF lcl_file=>ts_value_data."headder for data

    DATA: mv_package     TYPE devclass."package
    DATA: mv_language    TYPE sy-langu."language

    CONSTANTS c_doma  TYPE string VALUE 'DOMA'."domain
    CONSTANTS c_dtel  TYPE string VALUE 'DTEL'."data element
    CONSTANTS c_tabl  TYPE string VALUE 'TABL'."table
    CONSTANTS c_dd04v TYPE string VALUE 'DD04V'."
    CONSTANTS c_dd07v TYPE string VALUE 'DD07V'."
    CONSTANTS c_dd01v TYPE string VALUE 'DD01V'."
    CONSTANTS c_dd02v TYPE string VALUE 'DD02V'."
    CONSTANTS c_dd09l TYPE string VALUE 'DD09L'."
    CONSTANTS c_dd03p TYPE string VALUE 'DD03P'."

    METHODS constructor
      IMPORTING
        it_head TYPE tt_value_data OPTIONAL"header
        it_data TYPE tt_value_data OPTIONAL."data

    METHODS import_ddic_object.

    METHODS insert_package
      IMPORTING
                is_object        TYPE dwinactiv     "object
                iv_package       TYPE tadir-devclass"package
      RETURNING VALUE(rv_result) TYPE boole_d.      "result£¬true : sucess

  PRIVATE SECTION.

    DATA: mv_trkorr TYPE trkorr."transport

    METHODS set_ddic_table.

    METHODS create_doma.

    METHODS create_dtel.

    METHODS create_tabl.

    METHODS activate_object.

    METHODS read_db_log
      IMPORTING
        iv_logname TYPE ddmass-logname"log name
      EXPORTING
        ev_message TYPE string.

    METHODS check_exits
      IMPORTING
        VALUE(iv_objty)   TYPE string         "object type
        VALUE(iv_objname) TYPE char30         "object name
      RETURNING
        VALUE(rv_bool)    TYPE boole_d.        "return result

    METHODS set_transport.

ENDCLASS.

*&------------------------------------------------------------------------------------------- &*
*& class lcl_ddic_object  IMPLEMENTATION                                                      &*
*&------------------------------------------------------------------------------------------- &*
CLASS lcl_ddic_object IMPLEMENTATION.
*&---------------------------------------------------------------------*
*&  constructor
*&---------------------------------------------------------------------*
  METHOD constructor.
    mt_head = it_head.
    mt_data = it_data.
  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  set_ddic_table "set the uploaded data in the ddic object
*&---------------------------------------------------------------------*
  METHOD set_ddic_table.

*&------table
    DATA: ls_dd02v TYPE dd02v,
          ls_dd09l TYPE dd09l,
          ls_dd03p TYPE dd03p.

*&------data element
    DATA: ls_dd04v TYPE dd04v.

*&------domain
    DATA: ls_dd01v TYPE dd01v,
          ls_dd07v TYPE dd07v.

    DATA: ls_head       LIKE LINE OF mt_head.
    DATA: ls_data       LIKE LINE OF mt_data.
    DATA: ls_head_value LIKE LINE OF ls_data-valuetab.
    DATA: ls_data_value LIKE LINE OF ls_data-valuetab.

    FIELD-SYMBOLS: <fv_field>     TYPE any,
                   <fs_structure> TYPE any.

    IF mv_language IS INITIAL."language
      mv_language = sy-langu.
    ENDIF.

    SORT mt_head BY name.
    SORT mt_data BY name.

    LOOP AT mt_head INTO ls_head.
      READ TABLE mt_data INTO ls_data WITH KEY name = ls_head-name.
      IF sy-subrc = 0 AND ls_data-valuetab IS NOT INITIAL."data
        TRANSLATE ls_head-name TO UPPER CASE.
        "¸ù¾ÝÖµÌî³ä¶ÔÓ¦Êý¾Ý±íÊý¾Ý
        LOOP AT ls_data-valuetab INTO ls_data_value.

          AT NEW row.
            CASE ls_head-name.
              WHEN c_dd04v."data element
                APPEND INITIAL LINE TO mt_dd04v ASSIGNING <fs_structure>.
*&------labguage
                UNASSIGN <fv_field>.
                ASSIGN COMPONENT 'DTELMASTER' OF STRUCTURE <fs_structure> TO <fv_field>.
                IF <fv_field> IS ASSIGNED.
                  <fv_field> = mv_language.
                ENDIF.

              WHEN c_dd07v."fix value for domain
                APPEND INITIAL LINE TO mt_dd07v ASSIGNING <fs_structure>.

              WHEN c_dd01v."domain
                APPEND INITIAL LINE TO mt_dd01v ASSIGNING <fs_structure>.

                UNASSIGN <fv_field>.
                ASSIGN COMPONENT 'DOMMASTER' OF STRUCTURE <fs_structure> TO <fv_field>.
                IF <fv_field> IS ASSIGNED.
                  <fv_field> = mv_language.
                ENDIF.

              WHEN c_dd02v."table header
                APPEND INITIAL LINE TO mt_dd02v ASSIGNING <fs_structure>.

                UNASSIGN <fv_field>.
                ASSIGN COMPONENT 'MASTERLANGAND' OF STRUCTURE <fs_structure> TO <fv_field>.
                IF <fv_field> IS ASSIGNED.
                  <fv_field> = mv_language.
                ENDIF.

              WHEN c_dd09l."table technology
                APPEND INITIAL LINE TO mt_dd09l ASSIGNING <fs_structure>.

              WHEN c_dd03p."table field
                APPEND INITIAL LINE TO mt_dd03p ASSIGNING <fs_structure>.

            ENDCASE.
          ENDAT.

*&------lanuage
          UNASSIGN <fv_field>.
          ASSIGN COMPONENT 'DDLANGUAGE' OF STRUCTURE <fs_structure> TO <fv_field>.
          IF <fv_field> IS ASSIGNED AND <fv_field> IS INITIAL.
            <fv_field> = mv_language.
          ENDIF.

          READ TABLE ls_head-valuetab INTO ls_head_value WITH KEY column = ls_data_value-column.
          IF sy-subrc = 0.

            UNASSIGN <fv_field>.
            ASSIGN COMPONENT ls_head_value-value OF STRUCTURE <fs_structure> TO <fv_field>.
            IF <fv_field> IS ASSIGNED.
              <fv_field> = ls_data_value-value.
            ENDIF.
          ENDIF.
        ENDLOOP.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  create_doma "
*&---------------------------------------------------------------------*
  METHOD create_doma.

    DATA ls_error_object LIKE LINE OF mt_error_object. "
    DATA ls_act_object   TYPE dwinactiv.      "
    DATA ls_dd01v        TYPE dd01v.          "
    DATA ls_dd07v        TYPE dd07v.          "
    DATA lt_dd07v        TYPE TABLE OF dd07v. "
    DATA lv_tabix        TYPE sy-tabix.       "the row index

    SORT mt_dd01v BY domname.
    SORT mt_dd07v BY domname valpos.
    DELETE mt_dd01v WHERE domname IS INITIAL.
    DELETE mt_dd07v WHERE domname IS INITIAL.

    LOOP AT mt_dd01v INTO ls_dd01v.

*&------check existence
      IF check_exits( iv_objname = ls_dd01v-domname iv_objty = c_doma  ) = abap_true.
        ls_error_object-obj_name = ls_dd01v-domname.
        ls_error_object-object   = c_doma.
        ls_error_object-message  = TEXT-t05."'object exist'.
        APPEND ls_error_object TO mt_error_object.
        CONTINUE.
      ENDIF.

*&------assign package
      ls_act_object-obj_name = ls_dd01v-domname.
      ls_act_object-object   = c_doma.
      IF insert_package( iv_package = mv_package is_object = ls_act_object ) = abap_false.
        CONTINUE.
      ENDIF.

      CLEAR: lt_dd07v.
      READ TABLE mt_dd07v TRANSPORTING NO FIELDS WITH KEY domname = ls_dd01v-domname BINARY SEARCH.
      IF sy-subrc = 0.
        lv_tabix = sy-tabix."row index
        LOOP AT mt_dd07v INTO ls_dd07v FROM lv_tabix.
          IF ls_dd07v-domname <> ls_dd01v-domname.
            EXIT.
          ENDIF.
          APPEND ls_dd07v TO lt_dd07v.
        ENDLOOP.
      ENDIF.

      CALL FUNCTION 'DDIF_DOMA_PUT'
        EXPORTING
          name              = ls_dd01v-domname
          dd01v_wa          = ls_dd01v
        TABLES
          dd07v_tab         = lt_dd07v
        EXCEPTIONS
          doma_not_found    = 1
          name_inconsistent = 2
          doma_inconsistent = 3
          put_failure       = 4
          put_refused       = 5
          OTHERS            = 6.
      IF sy-subrc <> 0.
        ls_error_object-obj_name = ls_dd01v-domname.
        ls_error_object-object   = c_doma.
        MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO ls_error_object-message.
        APPEND ls_error_object TO mt_error_object.
      ELSE.
        APPEND ls_act_object TO mt_act_object.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  create_dtel "
*&---------------------------------------------------------------------*
  METHOD create_dtel.

    DATA ls_error_object LIKE LINE OF mt_error_object.
    DATA ls_act_object   TYPE dwinactiv.
    DATA ls_dd04v        TYPE dd04v.          "

    SORT mt_dd04v BY rollname.
    DELETE mt_dd04v WHERE rollname IS INITIAL.

    LOOP AT mt_dd04v INTO ls_dd04v.

*&------check existence
      IF check_exits( iv_objname = ls_dd04v-rollname iv_objty = c_dtel ) = abap_true.
        ls_error_object-obj_name = ls_dd04v-rollname.
        ls_error_object-object   = c_dtel.
        ls_error_object-message  = TEXT-t05."'¶ÔÏóÒÑ´æÔÚ'.
        APPEND ls_error_object TO mt_error_object.
        CONTINUE.
      ENDIF.

*&------assign package
      ls_act_object-obj_name = ls_dd04v-rollname.
      ls_act_object-object   = c_dtel.
      IF insert_package( iv_package = mv_package is_object = ls_act_object ) = abap_false.
        CONTINUE.
      ENDIF.

      CALL FUNCTION 'DDIF_DTEL_PUT'
        EXPORTING
          name              = ls_dd04v-rollname
          dd04v_wa          = ls_dd04v
        EXCEPTIONS
          dtel_not_found    = 1
          name_inconsistent = 2
          dtel_inconsistent = 3
          put_failure       = 4
          put_refused       = 5
          OTHERS            = 6.
      IF sy-subrc <> 0.
        ls_error_object-obj_name = ls_dd04v-domname.
        ls_error_object-object   = c_dtel.
        MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO ls_error_object-message.
        APPEND ls_error_object TO mt_error_object.
      ELSE.
        APPEND ls_act_object TO mt_act_object.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  create_tabl "
*&---------------------------------------------------------------------*
  METHOD create_tabl.

    DATA ls_error_object LIKE LINE OF mt_error_object.      "
    DATA ls_act_object   TYPE dwinactiv.      "
    DATA ls_dd02v        TYPE dd02v.          "
    DATA ls_dd09l        TYPE dd09l.          "
    DATA ls_dd03p        TYPE dd03p.          "
    DATA lt_dd03p        TYPE TABLE OF dd03p. "
    DATA lv_tabix        TYPE sy-tabix.       "

    SORT mt_dd02v BY tabname.
    SORT mt_dd09l BY tabname.
    SORT mt_dd03p BY tabname position.
    DELETE mt_dd02v WHERE tabname IS INITIAL.
    DELETE mt_dd09l WHERE tabname IS INITIAL.
    DELETE mt_dd03p WHERE tabname IS INITIAL.

    LOOP AT mt_dd02v INTO ls_dd02v.

      CLEAR: lt_dd03p.
      READ TABLE mt_dd03p TRANSPORTING NO FIELDS WITH KEY tabname = ls_dd02v-tabname BINARY SEARCH.
      IF sy-subrc = 0.
        lv_tabix = sy-tabix."ÐÐºÅ
        LOOP AT mt_dd03p INTO ls_dd03p FROM lv_tabix."±í×Ö¶Î
          IF ls_dd03p-tabname <> ls_dd02v-tabname.
            EXIT.
          ENDIF.
          APPEND ls_dd03p TO lt_dd03p.
        ENDLOOP.
      ENDIF.

      CLEAR ls_dd09l.
      READ TABLE mt_dd09l INTO ls_dd09l WITH KEY tabname = ls_dd02v-tabname BINARY SEARCH.
      IF sy-subrc = 0.

*&------check existence
        IF check_exits( iv_objname = ls_dd02v-tabname iv_objty = c_tabl ) = abap_true.
          ls_error_object-obj_name = ls_dd02v-tabname.
          ls_error_object-object   = c_tabl.
          ls_error_object-message  = TEXT-t05."'object exist'.
          APPEND ls_error_object TO mt_error_object.
          CONTINUE.
        ENDIF.

*&------assign package
        ls_act_object-obj_name = ls_dd02v-tabname.
        ls_act_object-object   = c_tabl.
        IF insert_package( iv_package = mv_package is_object = ls_act_object ) = abap_false.
          CONTINUE.
        ENDIF.

        CALL FUNCTION 'DDIF_TABL_PUT'
          EXPORTING
            name              = ls_dd02v-tabname
            dd02v_wa          = ls_dd02v
            dd09l_wa          = ls_dd09l
          TABLES
            dd03p_tab         = lt_dd03p
          EXCEPTIONS
            tabl_not_found    = 1
            name_inconsistent = 2
            tabl_inconsistent = 3
            put_failure       = 4
            put_refused       = 5
            OTHERS            = 6.
        IF sy-subrc <> 0.
          ls_error_object-obj_name = ls_dd02v-tabname.
          ls_error_object-object   = c_tabl.
          MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO ls_error_object-message.
          APPEND ls_error_object TO mt_error_object.
        ELSE.
          APPEND ls_act_object TO mt_act_object.
        ENDIF.
      ENDIF.
    ENDLOOP.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  activate_object "
*&---------------------------------------------------------------------*
  METHOD activate_object.

    DATA: lt_gentab     TYPE STANDARD TABLE OF dcgentb,
          lv_rc         TYPE sy-subrc,
          ls_gentab     LIKE LINE OF lt_gentab,
          lt_deltab     TYPE STANDARD TABLE OF dcdeltb,
          lt_action_tab TYPE STANDARD TABLE OF dctablres,
          lv_logname    TYPE ddmass-logname,
          lv_message    TYPE string.
    DATA: lv_popup TYPE abap_bool,
          lv_ddic  TYPE abap_bool.
    DATA: ls_error_object LIKE LINE OF mt_error_object.

    FIELD-SYMBOLS: <ls_object> LIKE LINE OF mt_act_object.

    CALL FUNCTION 'FUNCTION_EXISTS'
      EXPORTING
        funcname           = 'DD_MASS_ACT_C3'
      EXCEPTIONS
        function_not_exist = 1
        OTHERS             = 2.
    IF sy-subrc = 0.
      LOOP AT mt_act_object ASSIGNING <ls_object>.
        ls_gentab-tabix = sy-tabix.
        ls_gentab-type = <ls_object>-object.
        ls_gentab-name = <ls_object>-obj_name.
        INSERT ls_gentab INTO TABLE lt_gentab.
      ENDLOOP.
      lv_logname =  |BatchImport{ sy-datum }{ sy-uzeit }|.
      IF lt_gentab IS NOT INITIAL.
        CALL FUNCTION 'DD_MASS_ACT_C3'
          EXPORTING
            ddmode         = 'O'
            medium         = 'T' " transport order
            device         = 'T' " saves to table DDRPH?
            version        = 'M' " activate newest
            logname        = lv_logname
            write_log      = abap_true
            log_head_tail  = abap_true
            t_on           = space
            prid           = 1
          IMPORTING
            act_rc         = lv_rc
          TABLES
            gentab         = lt_gentab
            deltab         = lt_deltab
            cnvtab         = lt_action_tab
          EXCEPTIONS
            access_failure = 1
            no_objects     = 2
            locked         = 3
            internal_error = 4
            OTHERS         = 5.

        IF sy-subrc <> 0.
          LOOP AT mt_act_object ASSIGNING <ls_object>.
            READ TABLE lt_gentab TRANSPORTING NO FIELDS WITH KEY type = <ls_object>-object name = <ls_object>-obj_name.
            IF sy-subrc <> 0.
              CLEAR ls_error_object.
              <ls_object>-delet_flag = abap_true.
              MOVE-CORRESPONDING <ls_object> TO ls_error_object.
              ls_error_object-message = TEXT-t12."activate failed
              APPEND ls_error_object TO mt_error_object.
            ENDIF.
          ENDLOOP.
        ENDIF.

        DELETE mt_act_object WHERE delet_flag = abap_true.

        IF lv_rc > 0.
          me->read_db_log(
              EXPORTING
                iv_logname = lv_logname
              IMPORTING
                ev_message = lv_message ).
          MESSAGE lv_message TYPE 'S' DISPLAY LIKE 'E'.
        ENDIF.
      ENDIF.
    ELSE.
      IF mt_act_object IS NOT INITIAL.
        lv_popup = abap_true.
        lv_ddic = abap_true.
        CALL FUNCTION 'RS_WORKING_OBJECTS_ACTIVATE'
          EXPORTING
            activate_ddic_objects  = lv_ddic
            with_popup             = lv_popup
          TABLES
            objects                = mt_act_object
          EXCEPTIONS
            excecution_error       = 1
            cancelled              = 2
            insert_into_corr_error = 3
            OTHERS                 = 4.
        IF sy-subrc <> 0.
          MESSAGE TEXT-t12 TYPE 'S' DISPLAY LIKE 'E'.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  read_db_log "
*&---------------------------------------------------------------------*
  METHOD read_db_log.

    DATA: lt_lines      TYPE STANDARD TABLE OF trlog,
          lv_logname_db TYPE ddprh-protname,
          lv_log        TYPE string.

    FIELD-SYMBOLS: <ls_line> LIKE LINE OF lt_lines.

    lv_logname_db = iv_logname.

    CALL FUNCTION 'TR_READ_LOG'
      EXPORTING
        iv_log_type   = 'DB'
        iv_logname_db = lv_logname_db
      TABLES
        et_lines      = lt_lines
      EXCEPTIONS
        invalid_input = 1
        access_error  = 2
        OTHERS        = 3.

    IF sy-subrc <> 0.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO lv_log.
    ELSE.
      DELETE lt_lines WHERE severity <> 'E'.
      LOOP AT lt_lines ASSIGNING <ls_line>.
        lv_log = lv_log && <ls_line>-line.
      ENDLOOP.
    ENDIF.

    ev_message = lv_log.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  check_exits "
*&---------------------------------------------------------------------*
  METHOD check_exits.

    CASE iv_objty.
      WHEN c_doma."
        SELECT COUNT(*)
          FROM dd01l
          UP TO 1 ROWS
          WHERE domname = iv_objname
          AND as4local = 'A'
          AND as4vers = '0000'.
        rv_bool = boolc( sy-dbcnt <> 0 ).

      WHEN c_dtel."
        SELECT COUNT(*)
          FROM dd04l
          UP TO 1 ROWS
          WHERE rollname = iv_objname
          AND as4local = 'A'
          AND as4vers = '0000'.
        rv_bool = boolc( sy-dbcnt <> 0 ).

      WHEN c_tabl."
        SELECT COUNT(*)
          FROM dd02l
          UP TO 1 ROWS
          WHERE tabname = iv_objname
          AND as4local = 'A'
          AND as4vers = '0000'.
        rv_bool = boolc( sy-dbcnt <> 0 ).
    ENDCASE.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  insert_package "
*&---------------------------------------------------------------------*
  METHOD insert_package.

    DATA: lv_object       TYPE string,
          lv_object_class TYPE string,
          lv_package      TYPE devclass.

    DATA: ls_error_object LIKE LINE OF mt_error_object.

    lv_package      = iv_package.
    lv_object_class = 'DICT'.
    CONCATENATE is_object-object is_object-obj_name INTO lv_object.

    IF lv_package IS INITIAL.
      lv_package = '$TMP'."local
    ENDIF.

    CALL FUNCTION 'RS_CORR_INSERT'
      EXPORTING
        object              = lv_object
        object_class        = lv_object_class
        devclass            = lv_package
        master_language     = mv_language
        global_lock         = abap_true
        author              = sy-uname
        mode                = 'I'
        suppress_dialog     = abap_true
      EXCEPTIONS
        cancelled           = 1
        permission_failure  = 2
        unknown_objectclass = 3
        OTHERS              = 4.
    IF sy-subrc <> 0.
      rv_result = abap_false.
      CLEAR ls_error_object.
      MOVE-CORRESPONDING is_object TO ls_error_object.
      MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4 INTO ls_error_object-message.
      APPEND ls_error_object TO mt_error_object.
    ELSE.
      rv_result = abap_true.
    ENDIF.

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  import_ddic_object "
*&---------------------------------------------------------------------*
  METHOD import_ddic_object.

    me->set_ddic_table( ).
    me->set_transport( ).
    me->create_doma( ).
    me->create_dtel( ).
    me->create_tabl( ).
    me->activate_object( ).

  ENDMETHOD.
*&---------------------------------------------------------------------*
*&  set_transport
*&---------------------------------------------------------------------*
  METHOD set_transport.

    DATA ls_request         TYPE trwbo_request_header.

    IF mv_package IS NOT INITIAL AND ( mv_package+0(1) = 'Z' OR mv_package+0(1) = 'Y' )."
      CALL FUNCTION 'TR_REQUEST_CHOICE'
        IMPORTING
          es_request           = ls_request
        EXCEPTIONS
          invalid_request      = 1
          invalid_request_type = 2
          user_not_owner       = 3
          no_objects_appended  = 4
          enqueue_error        = 5
          cancelled_by_user    = 6
          recursive_call       = 7
          OTHERS               = 8.
      IF sy-subrc <> 0.
        MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
      ELSE.
        mv_trkorr = ls_request-trkorr.

*&------set request
        CALL FUNCTION 'TR_TASK_SET'
          EXPORTING
            iv_order          = mv_trkorr
          EXCEPTIONS
            invalid_username  = 1
            invalid_category  = 2
            invalid_client    = 3
            invalid_validdays = 4
            invalid_order     = 5
            invalid_task      = 6
            OTHERS            = 7.
        IF sy-subrc <> 0.
          MESSAGE ID sy-msgid TYPE 'E' NUMBER sy-msgno WITH sy-msgv1 sy-msgv2 sy-msgv3 sy-msgv4.
        ENDIF.
      ENDIF.
    ENDIF.

  ENDMETHOD.
ENDCLASS.

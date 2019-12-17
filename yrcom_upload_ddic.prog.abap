*&---------------------------------------------------------------------*
*& Report YRCOM_UPLOAD_DDIC
*&---------------------------------------------------------------------*
*& Transaction code       :
*& Program Name           : YRCOM_UPLOAD_DDIC
*& Created on             :
*& Functional Consultant  :
*& Developer              :SilentFirework
*&---------------------------------------------------------------------*
*& Purpose: batch create domain,data element, table
*&---------------------------------------------------------------------*
*& Change Record (new entries to the bottom)
*& Date        Developer Transport    Descriptions
*& ==========  ========  ===========  =================================*
*& 1. Create ddic object according the data from excel
*&---------------------------------------------------------------------*
REPORT yrcom_upload_ddic MESSAGE-ID zev.
INCLUDE yrcom_upload_ddic_class.
TABLES sscrfields.
*&---------------------------------------------------------------------*
* Data Definition
*&---------------------------------------------------------------------*
DATA: go_file         TYPE REF TO lcl_file.
DATA: go_ddic_object  TYPE REF TO lcl_ddic_object.

DATA: gv_user_action TYPE i. "User action

*&---------------------------------------------------------------------*
* Selection Screen definition
*&---------------------------------------------------------------------*
SELECTION-SCREEN: BEGIN OF BLOCK b1 WITH FRAME.
PARAMETERS p_path TYPE localfile MEMORY ID mid1.
PARAMETERS p_paka TYPE ko007-l_devclass DEFAULT '$TMP' OBLIGATORY.
SELECTION-SCREEN: END OF BLOCK b1.
*Activate the selection screen button
SELECTION-SCREEN: FUNCTION KEY 1.
*&---------------------------------------------------------------------*
* Initialization
*&---------------------------------------------------------------------*
INITIALIZATION.
*&------function button on selection screen
  DATA: lv_functxt TYPE smp_dyntxt.
  lv_functxt-icon_id   = icon_export.
  lv_functxt-icon_text = 'Download Template'(t04).
  sscrfields-functxt_01 = lv_functxt.

*&------initial file deal object
  CREATE OBJECT go_file.

*----------------------------------------------------------------------*
* AT SELECTION-SCREEN ON VALUE-REQUEST
*----------------------------------------------------------------------*
AT SELECTION-SCREEN ON VALUE-REQUEST FOR p_path.
  CALL METHOD go_file->open_select_dialog_upload(
    IMPORTING
      ev_user_action = gv_user_action ).
  IF gv_user_action <> cl_gui_frontend_services=>action_cancel."No cancel set the path
    p_path = go_file->mv_upload_path.
  ENDIF.

*&--------------------------------------------------------------------*
*  Ñ¡ÔñÆÁÄ»                                   *
*&--------------------------------------------------------------------*
AT SELECTION-SCREEN.
  CASE sy-ucomm.

    WHEN 'FC01'."download template
      CALL METHOD go_file->open_select_dialog_save( "get file path to download
        IMPORTING
          ev_user_action = gv_user_action ).
      IF gv_user_action NE cl_gui_frontend_services=>action_cancel."No cancel set the path
        CALL METHOD go_file->download_template( )."download template
      ENDIF.

    WHEN 'ONLI'."Ö´ÐÐ
      IF p_path IS INITIAL."file path cann't is null
        MESSAGE e095.
      ENDIF.

    WHEN OTHERS.
  ENDCASE.

*&---------------------------------------------------------------------*
* start of selection
*&---------------------------------------------------------------------*
START-OF-SELECTION.
  go_file->mv_upload_path = p_path.
  CALL METHOD go_file->upload_data( ).
*&------create DDIC object according the uploaded data
  CREATE OBJECT go_ddic_object
    EXPORTING
      it_head = go_file->mt_head
      it_data = go_file->mt_data.
  go_ddic_object->mv_package  = p_paka.
  go_ddic_object->mv_language = sy-langu.

*&---------------------------------------------------------------------*
* end of selection
*&---------------------------------------------------------------------*
END-OF-SELECTION.
  CALL METHOD go_ddic_object->import_ddic_object( ).
  PERFORM frm_write_result.
*&---------------------------------------------------------------------*
*&      Form  FRM_WRITE_RESULT
*&---------------------------------------------------------------------*
*       output result
*----------------------------------------------------------------------*
FORM frm_write_result .
  DATA:ls_error_object LIKE LINE OF go_ddic_object->mt_error_object,
       ls_act_object   LIKE LINE OF go_ddic_object->mt_act_object.

  IF go_ddic_object->mt_error_object IS NOT INITIAL.
    WRITE: / TEXT-t06.
    ULINE (210).
    WRITE: / '|', (10) TEXT-t08 ,'|', AT 15(15) TEXT-t09 ,'|', (180) TEXT-t10 , '|'.
    ULINE (210).
    LOOP AT go_ddic_object->mt_error_object INTO ls_error_object.
      WRITE: /'|', (10) ls_error_object-object UNDER TEXT-t08, '|',(15) ls_error_object-obj_name UNDER TEXT-t09 , '|', (180) ls_error_object-message UNDER TEXT-t10,'|'.
      ULINE (210).
    ENDLOOP.
  ENDIF.

  IF go_ddic_object->mt_act_object IS NOT INITIAL.
    WRITE: / TEXT-t07.
    ULINE (210).
    WRITE: / '|', (10) TEXT-t08 ,'|', AT 15(15) TEXT-t09 ,'|', (180) TEXT-t10.
    ULINE (210).
    LOOP AT go_ddic_object->mt_act_object INTO ls_act_object.
      WRITE: /'|',(10) ls_act_object-object UNDER TEXT-t08, '|',(15) ls_act_object-obj_name UNDER TEXT-t09 , '|',(180) TEXT-t11 UNDER TEXT-t10, '|'.
      ULINE (210).
    ENDLOOP.
  ENDIF.

ENDFORM.

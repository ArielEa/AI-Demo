SET SERVEROUTPUT ON
BEGIN
  FOR t IN (SELECT table_name FROM all_tables WHERE owner = 'MYSCHEMA') LOOP
    DECLARE
      v_count NUMBER;
    BEGIN
      EXECUTE IMMEDIATE 'SELECT COUNT(*) FROM MYSCHEMA.' || t.table_name INTO v_count;
      DBMS_OUTPUT.PUT_LINE('MYSCHEMA.' || t.table_name || ' => ' || v_count);
    EXCEPTION
      WHEN OTHERS THEN
        DBMS_OUTPUT.PUT_LINE('MYSCHEMA.' || t.table_name || ' => エラー（アクセス不可）');
    END;
  END LOOP;
END;
/

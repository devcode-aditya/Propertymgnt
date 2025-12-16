codeunit 408 DimensionManagement
{
    // LS = changes made by LS Retail
    // DP = changes made by DVS
    // DP6.01.02 HK 19SEP2013 : Code added to attach Default Dimension with Element Type on Agreement
    // Code          Date         Name              Description
    // APNT-HR1.0    13.11.13     Sangeeta          Added code for HR and Payroll Customization

    Permissions = TableData 80 = imd,
                  TableData 232 = imd,
                  TableData 355 = imd;

    trigger OnRun()
    begin
    end;

    var
        Text000: Label 'Dimensions %1 and %2 can''t be used concurrently.';
        Text001: Label 'Dimension combinations %1 - %2 and %3 - %4 can''t be used concurrently.';
        Text002: Label 'This Shortcut Dimension is not defined in the %1.';
        Text003: Label '%1 is not an available %2 for that dimension.';
        Text004: Label 'Select a %1 for the %2 %3.';
        Text005: Label 'Select a %1 for the %2 %3 for %4 %5.';
        Text006: Label 'Select %1 %2 for the %3 %4.';
        Text007: Label 'Select %1 %2 for the %3 %4 for %5 %6.';
        Text008: Label '%1 %2 must be blank.';
        Text009: Label '%1 %2 must be blank for %3 %4.';
        Text010: Label '%1 %2 must not be mentioned.';
        Text011: Label '%1 %2 must not be mentioned for %3 %4.';
        Text012: Label 'A %1 used in %2 has not been used in %3.';
        Text013: Label '%1 for %2 %3 is not the same in %4 and %5.';
        Text014: Label '%1 %2 is blocked.';
        Text015: Label '%1 %2 can''t be found.';
        Text016: Label '%1 %2 - %3 is blocked.';
        Text017: Label '%1 for %2 %3 - %4 must not be %5.';
        Text018: Label '%1 for %2 is missing.';
        TempDimBuf1: Record "Dimension Buffer" temporary;
        TempDimBuf2: Record "Dimension Buffer" temporary;
        ObjTransl: Record "Object Translation";
        DimValComb: Record "Dimension Value Combination";
        JobTaskDimTemp: Record "1002" temporary;
        TempDimCombInitialized: Boolean;
        TempDimCombEmpty: Boolean;
        DimCombErr: Text[250];
        DimValuePostingErr: Text[250];
        DimErr: Text[250];
        DocDimConsistencyErr: Text[250];
        HasGotGLSetup: Boolean;
        GLSetupShortcutDimCode: array[8] of Code[20];
        DimensionChanged: Boolean;
        CheckNewDimValue: Boolean;

    local procedure GetGLSetup()
    var
        GLSetup: Record "General Ledger Setup";
    begin
        IF NOT HasGotGLSetup THEN BEGIN
            GLSetup.GET;
            GLSetupShortcutDimCode[1] := GLSetup."Shortcut Dimension 1 Code";
            GLSetupShortcutDimCode[2] := GLSetup."Shortcut Dimension 2 Code";
            GLSetupShortcutDimCode[3] := GLSetup."Shortcut Dimension 3 Code";
            GLSetupShortcutDimCode[4] := GLSetup."Shortcut Dimension 4 Code";
            GLSetupShortcutDimCode[5] := GLSetup."Shortcut Dimension 5 Code";
            GLSetupShortcutDimCode[6] := GLSetup."Shortcut Dimension 6 Code";
            GLSetupShortcutDimCode[7] := GLSetup."Shortcut Dimension 7 Code";
            GLSetupShortcutDimCode[8] := GLSetup."Shortcut Dimension 8 Code";
            HasGotGLSetup := TRUE;
        END;
    end;

    procedure CheckJnlLineDimComb(var JnlLineDim: Record "Gen. Journal Line Dimension"): Boolean
    begin
        IF NOT TestDimValue(JnlLineDim) THEN
            EXIT(FALSE);
        IF CheckNewDimValue THEN
            IF NOT TestNewDimValue(JnlLineDim) THEN
                EXIT(FALSE);
        EXIT(TRUE);
    end;

    procedure CheckDocDimComb(var DocDim: Record "Document Dimension"): Boolean
    var
        i: Integer;
    begin
        TempDimBuf1.RESET;
        TempDimBuf1.DELETEALL;
        IF DocDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := DATABASE::"Document Dimension";
                TempDimBuf1."Entry No." := i;
                TempDimBuf1."Dimension Code" := DocDim."Dimension Code";
                TempDimBuf1."Dimension Value Code" := DocDim."Dimension Value Code";
                TempDimBuf1.INSERT;
                i := i + 1;
            UNTIL DocDim.NEXT = 0;
        END;
        EXIT(CheckDimComb);
    end;

    procedure CheckServContractDimComb(var ServContractDim: Record "389"): Boolean
    var
        i: Integer;
    begin
        TempDimBuf1.RESET;
        TempDimBuf1.DELETEALL;
        IF ServContractDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := DATABASE::"Service Contract Dimension";
                TempDimBuf1."Entry No." := i;
                TempDimBuf1."Dimension Code" := ServContractDim."Dimension Code";
                TempDimBuf1."Dimension Value Code" := ServContractDim."Dimension Value Code";
                TempDimBuf1.INSERT;
                i := i + 1;
            UNTIL ServContractDim.NEXT = 0;
        END;
        EXIT(CheckDimComb);
    end;

    procedure CheckDimBuffer(var DimBuffer: Record "Dimension Buffer"): Boolean
    var
        i: Integer;
    begin
        TempDimBuf1.RESET;
        TempDimBuf1.DELETEALL;
        IF DimBuffer.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := DATABASE::"Dimension Buffer";
                TempDimBuf1."Entry No." := i;
                TempDimBuf1."Dimension Code" := DimBuffer."Dimension Code";
                TempDimBuf1."Dimension Value Code" := DimBuffer."Dimension Value Code";
                TempDimBuf1.INSERT;
                i := i + 1;
            UNTIL DimBuffer.NEXT = 0;
        END;
        EXIT(CheckDimComb);
    end;

    local procedure CheckDimComb(): Boolean
    var
        DimComb: Record "350";
        DimValComb: Record "Dimension Value Combination";
        CurrentDimCode: Code[20];
        CurrentDimValCode: Code[20];
        DimFilter: Text[1024];
        FilterTooLong: Boolean;
    begin
        IF NOT TempDimCombInitialized THEN BEGIN
            TempDimCombInitialized := TRUE;
            IF DimComb.ISEMPTY THEN
                TempDimCombEmpty := TRUE;
        END;

        IF TempDimCombEmpty THEN
            EXIT(TRUE);

        IF NOT TempDimBuf1.FINDSET THEN
            EXIT(TRUE)
        ELSE
            REPEAT
                IF STRLEN(DimFilter) + 1 + STRLEN(TempDimBuf1."Dimension Code") > MAXSTRLEN(DimFilter) THEN
                    FilterTooLong := TRUE
                ELSE
                    IF DimFilter = '' THEN
                        DimFilter := TempDimBuf1."Dimension Code"
                    ELSE
                        DimFilter := DimFilter + '|' + TempDimBuf1."Dimension Code";
            UNTIL FilterTooLong OR (TempDimBuf1.NEXT = 0);

        IF NOT FilterTooLong THEN BEGIN
            DimComb.SETFILTER("Dimension 1 Code", DimFilter);
            DimComb.SETFILTER("Dimension 2 Code", DimFilter);
            IF DimComb.FINDSET THEN
                REPEAT
                    IF DimComb."Combination Restriction" = DimComb."Combination Restriction"::Blocked THEN BEGIN
                        DimCombErr := STRSUBSTNO(Text000, DimComb."Dimension 1 Code", DimComb."Dimension 2 Code");
                        EXIT(FALSE);
                    END ELSE BEGIN
                        TempDimBuf1.SETRANGE("Dimension Code", DimComb."Dimension 1 Code");
                        TempDimBuf1.FINDFIRST;
                        CurrentDimCode := TempDimBuf1."Dimension Code";
                        CurrentDimValCode := TempDimBuf1."Dimension Value Code";
                        TempDimBuf1.SETRANGE("Dimension Code", DimComb."Dimension 2 Code");
                        TempDimBuf1.FINDFIRST;
                        IF NOT
                          CheckDimValueComb(
                            TempDimBuf1."Dimension Code", TempDimBuf1."Dimension Value Code",
                            CurrentDimCode, CurrentDimValCode)
                          THEN
                            EXIT(FALSE);
                        IF NOT
                          CheckDimValueComb(
                            CurrentDimCode, CurrentDimValCode,
                            TempDimBuf1."Dimension Code", TempDimBuf1."Dimension Value Code")
                          THEN
                            EXIT(FALSE);
                    END;
                UNTIL DimComb.NEXT = 0;
            EXIT(TRUE);
        END;

        WHILE TempDimBuf1.FINDFIRST DO BEGIN
            CurrentDimCode := TempDimBuf1."Dimension Code";
            CurrentDimValCode := TempDimBuf1."Dimension Value Code";
            TempDimBuf1.DELETE;
            IF TempDimBuf1.FINDSET THEN
                REPEAT
                    IF CurrentDimCode > TempDimBuf1."Dimension Code" THEN BEGIN
                        IF DimComb.GET(TempDimBuf1."Dimension Code", CurrentDimCode) THEN BEGIN
                            IF DimComb."Combination Restriction" = DimComb."Combination Restriction"::Blocked THEN BEGIN
                                DimCombErr :=
                                  STRSUBSTNO(
                                    Text000,
                                    TempDimBuf1."Dimension Code", CurrentDimCode);
                                EXIT(FALSE);
                            END ELSE
                                IF NOT
                                  CheckDimValueComb(
                                    TempDimBuf1."Dimension Code", TempDimBuf1."Dimension Value Code",
                                    CurrentDimCode, CurrentDimValCode)
                                THEN
                                    EXIT(FALSE);
                        END;
                    END ELSE BEGIN
                        IF DimComb.GET(CurrentDimCode, TempDimBuf1."Dimension Code") THEN BEGIN
                            IF DimComb."Combination Restriction" = DimComb."Combination Restriction"::Blocked THEN BEGIN
                                DimCombErr :=
                                  STRSUBSTNO(
                                    Text000,
                                    CurrentDimCode, TempDimBuf1."Dimension Code");
                                EXIT(FALSE);
                            END ELSE
                                IF NOT
                                   CheckDimValueComb(
                                     CurrentDimCode, CurrentDimValCode, TempDimBuf1."Dimension Code",
                                     TempDimBuf1."Dimension Value Code")
                                THEN
                                    EXIT(FALSE);
                        END;
                    END;
                UNTIL TempDimBuf1.NEXT = 0;
        END;
        EXIT(TRUE);
    end;

    local procedure CheckDimValueComb(Dim1: Code[20]; Dim1Value: Code[20]; Dim2: Code[20]; Dim2Value: Code[20]): Boolean
    begin
        IF DimValComb.GET(Dim1, Dim1Value, Dim2, Dim2Value) THEN BEGIN
            DimCombErr :=
              STRSUBSTNO(Text001,
                Dim1, Dim1Value, Dim2, Dim2Value);
            EXIT(FALSE);
        END ELSE
            EXIT(TRUE);
    end;

    procedure GetDimCombErr(): Text[250]
    begin
        EXIT(DimCombErr);
    end;

    procedure UpdateDefaultDim(TableID: Integer; No: Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DefaultDim: Record "352";
    begin
        GetGLSetup;
        IF DefaultDim.GET(TableID, No, GLSetupShortcutDimCode[1]) THEN
            GlobalDim1Code := DefaultDim."Dimension Value Code"
        ELSE
            GlobalDim1Code := '';
        IF DefaultDim.GET(TableID, No, GLSetupShortcutDimCode[2]) THEN
            GlobalDim2Code := DefaultDim."Dimension Value Code"
        ELSE
            GlobalDim2Code := '';
    end;

    procedure InsertJnlLineDim(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    begin
        IF TempDimBuf2.FINDFIRST THEN
            UpdateJnlLineDefaultDim(TableID, JnlTemplateName, JnlBatchName, JnlLineNo, AllocationLineNo, GlobalDim1Code, GlobalDim2Code);
    end;

    procedure UpdateJnlLineDefaultDim(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        JnlLineDim: Record "Gen. Journal Line Dimension";
        Dim: Record "348";
        DimValue: Record "349";
        RecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        JnlLineDim.SETRANGE("Table ID", TableID);
        JnlLineDim.SETRANGE("Journal Template Name", JnlTemplateName);
        JnlLineDim.SETRANGE("Journal Batch Name", JnlBatchName);
        JnlLineDim.SETRANGE("Journal Line No.", JnlLineNo);
        JnlLineDim.SETRANGE("Allocation Line No.", AllocationLineNo);
        IF NOT JnlLineDim.ISEMPTY THEN
            JnlLineDim.DELETEALL;
        GlobalDim1Code := '';
        GlobalDim2Code := '';
        IF TempDimBuf2.FINDSET THEN BEGIN
            REPEAT
                JnlLineDim.INIT;
                JnlLineDim.VALIDATE("Table ID", TableID);
                JnlLineDim.VALIDATE("Journal Template Name", JnlTemplateName);
                JnlLineDim.VALIDATE("Journal Batch Name", JnlBatchName);
                JnlLineDim.VALIDATE("Journal Line No.", JnlLineNo);
                JnlLineDim.VALIDATE("Allocation Line No.", AllocationLineNo);
                JnlLineDim."Dimension Code" := TempDimBuf2."Dimension Code";
                JnlLineDim."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                JnlLineDim."New Dimension Value Code" := TempDimBuf2."New Dimension Value Code";
                JnlLineDim.INSERT;
                RecRef.GETTABLE(JnlLineDim);
                ChangeLogMgt.LogInsertion(RecRef);
                IF JnlLineDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                    GlobalDim1Code := JnlLineDim."Dimension Value Code";
                IF JnlLineDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                    GlobalDim2Code := JnlLineDim."Dimension Value Code";
            UNTIL TempDimBuf2.NEXT = 0;
            TempDimBuf2.RESET;
            TempDimBuf2.DELETEALL;
        END;
    end;

    procedure GetJnlLineDefaultDim(var JnlLineDim: Record "Gen. Journal Line Dimension")
    begin
        IF NOT JnlLineDim.ISEMPTY THEN
            JnlLineDim.DELETEALL;
        IF TempDimBuf2.FINDSET THEN
            REPEAT
                JnlLineDim."Dimension Code" := TempDimBuf2."Dimension Code";
                JnlLineDim."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                JnlLineDim."New Dimension Value Code" := TempDimBuf2."New Dimension Value Code";
                JnlLineDim.INSERT;
            UNTIL TempDimBuf2.NEXT = 0;
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
    end;

    procedure GetPreviousDocDefaultDim(TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer; FromTableID: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DocDim: Record "Document Dimension";
    begin
        GetGLSetup;
        TempDimBuf1.RESET;
        TempDimBuf1.DELETEALL;
        DocDim.SETRANGE("Table ID", TableID);
        DocDim.SETRANGE("Document Type", DocType);
        DocDim.SETRANGE("Document No.", DocNo);
        DocDim.SETRANGE("Line No.", LineNo);
        IF DocDim.FINDSET THEN BEGIN
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := FromTableID;
                TempDimBuf1."Entry No." := 0;
                TempDimBuf1."Dimension Code" := DocDim."Dimension Code";
                TempDimBuf1."Dimension Value Code" := DocDim."Dimension Value Code";
                TempDimBuf1.INSERT;
                IF GLSetupShortcutDimCode[1] = TempDimBuf1."Dimension Code" THEN
                    GlobalDim1Code := TempDimBuf1."Dimension Value Code";
                IF GLSetupShortcutDimCode[2] = TempDimBuf1."Dimension Code" THEN
                    GlobalDim2Code := TempDimBuf1."Dimension Value Code";
            UNTIL DocDim.NEXT = 0;
        END;
    end;

    procedure GetPreviousProdDocDefaultDim(TableID: Integer; DocStatus: Option; DocNo: Code[20]; DocLineNo: Integer; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        ProdDocDim: Record "358";
    begin
        GetGLSetup;
        TempDimBuf1.RESET;
        TempDimBuf1.DELETEALL;
        ProdDocDim.SETRANGE("Table ID", TableID);
        ProdDocDim.SETRANGE("Document Status", DocStatus);
        ProdDocDim.SETRANGE("Document No.", DocNo);
        ProdDocDim.SETRANGE("Document Line No.", DocLineNo);
        ProdDocDim.SETRANGE("Line No.", LineNo);
        IF ProdDocDim.FINDSET THEN BEGIN
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := 0;
                TempDimBuf1."Entry No." := 0;
                TempDimBuf1."Dimension Code" := ProdDocDim."Dimension Code";
                TempDimBuf1."Dimension Value Code" := ProdDocDim."Dimension Value Code";
                TempDimBuf1.INSERT;
                IF GLSetupShortcutDimCode[1] = TempDimBuf1."Dimension Code" THEN
                    GlobalDim1Code := TempDimBuf1."Dimension Value Code";
                IF GLSetupShortcutDimCode[2] = TempDimBuf1."Dimension Code" THEN
                    GlobalDim2Code := TempDimBuf1."Dimension Value Code";
            UNTIL ProdDocDim.NEXT = 0;
        END;
    end;

    procedure InsertDocDim(TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    begin
        IF TempDimBuf2.FINDFIRST THEN
            UpdateDocDefaultDim(TableID, DocType, DocNo, LineNo, GlobalDim1Code, GlobalDim2Code);
    end;

    procedure UpdateDocDefaultDim(TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DocDim: Record "Document Dimension";
        RecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        DocDim.SETRANGE("Table ID", TableID);
        DocDim.SETRANGE("Document Type", DocType);
        DocDim.SETRANGE("Document No.", DocNo);
        DocDim.SETRANGE("Line No.", LineNo);
        IF NOT DocDim.ISEMPTY THEN
            DocDim.DELETEALL;
        GlobalDim1Code := '';
        GlobalDim2Code := '';
        IF TempDimBuf2.FINDSET THEN BEGIN
            REPEAT
                DocDim.INIT;
                DocDim.VALIDATE("Table ID", TableID);
                DocDim.VALIDATE("Document Type", DocType);
                DocDim.VALIDATE("Document No.", DocNo);
                DocDim.VALIDATE("Line No.", LineNo);
                DocDim."Dimension Code" := TempDimBuf2."Dimension Code";
                DocDim."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                DocDim.INSERT;
                RecRef.GETTABLE(DocDim);
                ChangeLogMgt.LogInsertion(RecRef);
                IF DocDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                    GlobalDim1Code := DocDim."Dimension Value Code";
                IF DocDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                    GlobalDim2Code := DocDim."Dimension Value Code";
            UNTIL TempDimBuf2.NEXT = 0;
            TempDimBuf2.RESET;
            TempDimBuf2.DELETEALL;
        END;
    end;

    procedure ExtractDocDefaultDim(TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer; var DocDim: Record "Document Dimension")
    begin
        GetGLSetup;
        IF TempDimBuf2.FINDSET THEN BEGIN
            REPEAT
                DocDim.INIT;
                DocDim.VALIDATE("Table ID", TableID);
                DocDim.VALIDATE("Document Type", DocType);
                DocDim.VALIDATE("Document No.", DocNo);
                DocDim.VALIDATE("Line No.", LineNo);
                DocDim."Dimension Code" := TempDimBuf2."Dimension Code";
                DocDim."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                DocDim.INSERT;
            UNTIL TempDimBuf2.NEXT = 0;
            TempDimBuf2.RESET;
            TempDimBuf2.DELETEALL;
        END;
    end;

    procedure InsertProdDocDim(TableID: Integer; DocStatus: Option; DocNo: Code[20]; DocLineNo: Integer; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    begin
        IF TempDimBuf2.FINDFIRST THEN
            UpdateProdDocDefaultDim(TableID, DocStatus, DocNo, DocLineNo, LineNo, GlobalDim1Code, GlobalDim2Code);
    end;

    procedure UpdateProdDocDefaultDim(TableID: Integer; DocStatus: Option; DocNo: Code[20]; DocLineNo: Integer; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        ProdDocDim: Record "358";
        RecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        ProdDocDim.SETRANGE("Table ID", TableID);
        ProdDocDim.SETRANGE("Document Status", DocStatus);
        ProdDocDim.SETRANGE("Document No.", DocNo);
        ProdDocDim.SETRANGE("Document Line No.", DocLineNo);
        ProdDocDim.SETRANGE("Line No.", LineNo);
        IF NOT ProdDocDim.ISEMPTY THEN
            ProdDocDim.DELETEALL;
        GlobalDim1Code := '';
        GlobalDim2Code := '';
        IF TempDimBuf2.FINDSET THEN BEGIN
            REPEAT
                ProdDocDim.INIT;
                ProdDocDim.VALIDATE("Table ID", TableID);
                ProdDocDim.VALIDATE("Document Status", DocStatus);
                ProdDocDim.VALIDATE("Document No.", DocNo);
                ProdDocDim.VALIDATE("Document Line No.", DocLineNo);
                ProdDocDim.VALIDATE("Line No.", LineNo);
                ProdDocDim."Dimension Code" := TempDimBuf2."Dimension Code";
                ProdDocDim."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                ProdDocDim.INSERT;
                RecRef.GETTABLE(ProdDocDim);
                ChangeLogMgt.LogInsertion(RecRef);
                IF ProdDocDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                    GlobalDim1Code := ProdDocDim."Dimension Value Code";
                IF ProdDocDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                    GlobalDim2Code := ProdDocDim."Dimension Value Code";
            UNTIL TempDimBuf2.NEXT = 0;
            TempDimBuf2.RESET;
            TempDimBuf2.DELETEALL;
        END;
    end;

    procedure InsertServContractDim(TableID: Integer; Type: Option; No: Code[20]; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    begin
        IF TempDimBuf2.FINDFIRST THEN
            UpdateServcontractDim(TableID, Type, No, LineNo, GlobalDim1Code, GlobalDim2Code);
    end;

    procedure UpdateServcontractDim(TableID: Integer; Type: Option; No: Code[20]; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        ServContractDim: Record "389";
        RecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        ServContractDim.SETRANGE("Table ID", TableID);
        ServContractDim.SETRANGE(Type, Type);
        ServContractDim.SETRANGE("No.", No);
        ServContractDim.SETRANGE("Line No.", LineNo);
        IF NOT ServContractDim.ISEMPTY THEN
            ServContractDim.DELETEALL;
        GlobalDim1Code := '';
        GlobalDim2Code := '';
        IF TempDimBuf2.FINDSET THEN BEGIN
            REPEAT
                ServContractDim.INIT;
                ServContractDim.VALIDATE("Table ID", TableID);
                ServContractDim.VALIDATE(Type, Type);
                ServContractDim.VALIDATE("No.", No);
                ServContractDim.VALIDATE("Line No.", LineNo);
                ServContractDim."Dimension Code" := TempDimBuf2."Dimension Code";
                ServContractDim."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                ServContractDim.INSERT;
                RecRef.GETTABLE(ServContractDim);
                ChangeLogMgt.LogInsertion(RecRef);
                IF ServContractDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                    GlobalDim1Code := ServContractDim."Dimension Value Code";
                IF ServContractDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                    GlobalDim2Code := ServContractDim."Dimension Value Code";
            UNTIL TempDimBuf2.NEXT = 0;
            TempDimBuf2.RESET;
            TempDimBuf2.DELETEALL;
        END;
    end;

    procedure UpdateDefaultDimNewDimValue()
    begin
        WITH TempDimBuf2 DO
            IF FINDSET THEN
                REPEAT
                    "New Dimension Value Code" := "Dimension Value Code";
                    MODIFY;
                UNTIL NEXT = 0;
    end;

    procedure GetDefaultDim(TableID: array[10] of Integer; No: array[10] of Code[20]; "Source Code": Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DefaultDimPriority1: Record "354";
        DefaultDimPriority2: Record "354";
        DefaultDim: Record "352";
        i: Integer;
        j: Integer;
        NoFilter: array[2] of Code[20];
    begin
        GetGLSetup;
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF TempDimBuf1.FINDSET THEN BEGIN
            REPEAT
                TempDimBuf2.INIT;
                TempDimBuf2 := TempDimBuf1;
                TempDimBuf2.INSERT;
            UNTIL TempDimBuf1.NEXT = 0;
        END;
        NoFilter[2] := '';
        FOR i := 1 TO ARRAYLEN(TableID) DO BEGIN
            IF (TableID[i] <> 0) AND (No[i] <> '') THEN BEGIN
                DefaultDim.SETRANGE("Table ID", TableID[i]);
                NoFilter[1] := No[i];
                FOR j := 1 TO 2 DO BEGIN
                    DefaultDim.SETRANGE("No.", NoFilter[j]);
                    IF DefaultDim.FINDSET THEN BEGIN
                        REPEAT
                            IF DefaultDim."Dimension Value Code" <> '' THEN BEGIN
                                TempDimBuf2.SETRANGE("Dimension Code", DefaultDim."Dimension Code");
                                IF NOT TempDimBuf2.FINDFIRST THEN BEGIN
                                    TempDimBuf2.INIT;
                                    TempDimBuf2."Table ID" := DefaultDim."Table ID";
                                    TempDimBuf2."Entry No." := 0;
                                    TempDimBuf2."Dimension Code" := DefaultDim."Dimension Code";
                                    TempDimBuf2."Dimension Value Code" := DefaultDim."Dimension Value Code";
                                    TempDimBuf2.INSERT;
                                END ELSE BEGIN
                                    IF DefaultDimPriority1.GET("Source Code", DefaultDim."Table ID") THEN BEGIN
                                        IF DefaultDimPriority2.GET("Source Code", TempDimBuf2."Table ID") THEN BEGIN
                                            IF DefaultDimPriority1.Priority < DefaultDimPriority2.Priority THEN BEGIN
                                                TempDimBuf2.DELETE;
                                                TempDimBuf2."Table ID" := DefaultDim."Table ID";
                                                TempDimBuf2."Entry No." := 0;
                                                TempDimBuf2."Dimension Value Code" := DefaultDim."Dimension Value Code";
                                                TempDimBuf2.INSERT;
                                            END;
                                        END ELSE BEGIN
                                            TempDimBuf2.DELETE;
                                            TempDimBuf2."Table ID" := DefaultDim."Table ID";
                                            TempDimBuf2."Entry No." := 0;
                                            TempDimBuf2."Dimension Value Code" := DefaultDim."Dimension Value Code";
                                            TempDimBuf2.INSERT;
                                        END;
                                    END;
                                END;
                                IF GLSetupShortcutDimCode[1] = TempDimBuf2."Dimension Code" THEN
                                    GlobalDim1Code := TempDimBuf2."Dimension Value Code";
                                IF GLSetupShortcutDimCode[2] = TempDimBuf2."Dimension Code" THEN
                                    GlobalDim2Code := TempDimBuf2."Dimension Value Code";
                            END;
                        UNTIL DefaultDim.NEXT = 0;
                    END;
                END;
            END;
        END;
        TempDimBuf2.RESET;
    end;

    procedure GetDocDim(TableID: Integer; DocType: Option; DocNo: Code[20]; DocLineNo: Integer; "Source Code": Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DocDim: Record "Document Dimension";
    begin
        GetGLSetup;
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF TempDimBuf1.FINDSET THEN BEGIN
            REPEAT
                TempDimBuf2.INIT;
                TempDimBuf2 := TempDimBuf1;
                TempDimBuf2.INSERT;
            UNTIL TempDimBuf1.NEXT = 0;
        END;
        IF (TableID <> 0) AND (DocNo <> '') THEN BEGIN
            DocDim.SETRANGE("Table ID", TableID);
            DocDim.SETRANGE("Document Type", DocType);
            DocDim.SETRANGE("Document No.", DocNo);
            DocDim.SETRANGE("Line No.", DocLineNo);
            IF DocDim.FINDSET THEN BEGIN
                REPEAT
                    IF DocDim."Dimension Value Code" <> '' THEN BEGIN
                        TempDimBuf2.SETRANGE("Dimension Code", DocDim."Dimension Code");
                        IF NOT TempDimBuf2.FINDFIRST THEN BEGIN
                            TempDimBuf2.INIT;
                            TempDimBuf2."Table ID" := DocDim."Table ID";
                            TempDimBuf2."Entry No." := 0;
                            TempDimBuf2."Dimension Code" := DocDim."Dimension Code";
                            TempDimBuf2."Dimension Value Code" := DocDim."Dimension Value Code";
                            TempDimBuf2.INSERT;
                        END;
                        IF GLSetupShortcutDimCode[1] = TempDimBuf2."Dimension Code" THEN
                            GlobalDim1Code := TempDimBuf2."Dimension Value Code";
                        IF GLSetupShortcutDimCode[2] = TempDimBuf2."Dimension Code" THEN
                            GlobalDim2Code := TempDimBuf2."Dimension Value Code";
                    END;
                UNTIL DocDim.NEXT = 0;
            END;
        END;
        TempDimBuf2.RESET;
    end;

    procedure GetProdDocDim(TableID: array[10] of Integer; No: array[10] of Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        ProdDocDim: Record "358";
        i: Integer;
        No2: Integer;
    begin
        GetGLSetup;
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF TempDimBuf1.FINDSET THEN BEGIN
            REPEAT
                TempDimBuf2.INIT;
                TempDimBuf2 := TempDimBuf1;
                TempDimBuf2.INSERT;
            UNTIL TempDimBuf1.NEXT = 0;
        END;

        ProdDocDim.SETRANGE("Document Status", ProdDocDim."Document Status"::Released);

        FOR i := 1 TO ARRAYLEN(TableID) DO BEGIN
            IF (TableID[i] <> 0) AND (No[i] <> '') THEN BEGIN
                CASE i OF
                    1:
                        BEGIN
                            ProdDocDim.SETRANGE("Table ID", TableID[i]);
                            ProdDocDim.SETRANGE("Document No.", No[i]);
                            ProdDocDim.SETRANGE("Document Line No.", 0);
                        END;
                    2:
                        BEGIN
                            ProdDocDim.SETRANGE("Table ID", TableID[i]);
                            EVALUATE(No2, No[i]);
                            ProdDocDim.SETRANGE("Document Line No.", No2);
                        END;
                    3:
                        BEGIN
                            ProdDocDim.SETRANGE("Table ID", TableID[i]);
                            EVALUATE(No2, No[i]);
                            ProdDocDim.SETRANGE("Line No.", No2);
                        END;
                END;

                IF ProdDocDim.FINDSET THEN BEGIN
                    REPEAT
                        IF ProdDocDim."Dimension Value Code" <> '' THEN BEGIN
                            TempDimBuf2.SETRANGE("Dimension Code", ProdDocDim."Dimension Code");

                            IF TempDimBuf2.FINDFIRST THEN
                                TempDimBuf2.DELETE;
                            TempDimBuf2.INIT;
                            TempDimBuf2."Table ID" := ProdDocDim."Table ID";
                            TempDimBuf2."Entry No." := 0;
                            TempDimBuf2."Dimension Code" := ProdDocDim."Dimension Code";
                            TempDimBuf2."Dimension Value Code" := ProdDocDim."Dimension Value Code";
                            TempDimBuf2.INSERT;

                            IF GLSetupShortcutDimCode[1] = TempDimBuf2."Dimension Code" THEN
                                GlobalDim1Code := TempDimBuf2."Dimension Value Code";
                            IF GLSetupShortcutDimCode[2] = TempDimBuf2."Dimension Code" THEN
                                GlobalDim2Code := TempDimBuf2."Dimension Value Code";
                        END;
                    UNTIL ProdDocDim.NEXT = 0;
                END;
            END;
        END;
        TempDimBuf2.RESET;
    end;

    procedure TypeToTableID1(Type: Option "G/L Account",Customer,Vendor,"Bank Account","Fixed Asset","IC Partner"): Integer
    begin
        CASE Type OF
            Type::"G/L Account":
                EXIT(DATABASE::"G/L Account");
            Type::Customer:
                EXIT(DATABASE::Customer);
            Type::Vendor:
                EXIT(DATABASE::Vendor);
            Type::"Bank Account":
                EXIT(DATABASE::"Bank Account");
            Type::"Fixed Asset":
                EXIT(DATABASE::"Fixed Asset");
            Type::"IC Partner":
                EXIT(DATABASE::"IC Partner");
        END;
    end;

    procedure TypeToTableID2(Type: Option Resource,Item,"G/L Account"): Integer
    begin
        CASE Type OF
            Type::Resource:
                EXIT(DATABASE::Resource);
            Type::Item:
                EXIT(DATABASE::Item);
            Type::"G/L Account":
                EXIT(DATABASE::"G/L Account");
        END;
    end;

    procedure TypeToTableID3(Type: Option " ","G/L Account",Item,Resource,"Fixed Asset","Charge (Item)"): Integer
    begin
        CASE Type OF
            Type::" ":
                EXIT(0);
            Type::"G/L Account":
                EXIT(DATABASE::"G/L Account");
            Type::Item:
                EXIT(DATABASE::Item);
            Type::Resource:
                EXIT(DATABASE::Resource);
            Type::"Fixed Asset":
                EXIT(DATABASE::"Fixed Asset");
            Type::"Charge (Item)":
                EXIT(DATABASE::"Item Charge");
        END;
    end;

    procedure TypeToTableID4(Type: Option " ",Item,Resource,Cost): Integer
    begin
        CASE Type OF
            Type::" ":
                EXIT(0);
            Type::Item:
                EXIT(DATABASE::Item);
            Type::Resource:
                EXIT(DATABASE::Resource);
            Type::Cost:
                EXIT(DATABASE::"Service Cost");
        END;
    end;

    procedure TypeToTableID5(Type: Option " ",Item,Resource,Cost,"G/L Account"): Integer
    begin
        CASE Type OF
            Type::" ":
                EXIT(0);
            Type::Item:
                EXIT(DATABASE::Item);
            Type::Resource:
                EXIT(DATABASE::Resource);
            Type::Cost:
                EXIT(DATABASE::"Service Cost");
            Type::"G/L Account":
                EXIT(DATABASE::"G/L Account");
        END;
    end;

    procedure DeleteDefaultDim(TableID: Integer; No: Code[20])
    var
        DefaultDim: Record "352";
    begin
        DefaultDim.SETRANGE("Table ID", TableID);
        DefaultDim.SETRANGE("No.", No);
        IF NOT DefaultDim.ISEMPTY THEN
            DefaultDim.DELETEALL;
    end;

    procedure DeleteJnlLineDim(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer)
    var
        JnlLineDim: Record "Gen. Journal Line Dimension";
    begin
        JnlLineDim.SETRANGE("Table ID", TableID);
        JnlLineDim.SETRANGE("Journal Template Name", JnlTemplateName);
        JnlLineDim.SETRANGE("Journal Batch Name", JnlBatchName);
        JnlLineDim.SETRANGE("Journal Line No.", JnlLineNo);
        JnlLineDim.SETRANGE("Allocation Line No.", AllocationLineNo);
        IF NOT JnlLineDim.ISEMPTY THEN
            JnlLineDim.DELETEALL;
    end;

    procedure DeleteDocDim(TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer)
    var
        DocDim: Record "Document Dimension";
    begin
        DocDim.SETRANGE("Table ID", TableID);
        DocDim.SETRANGE("Document Type", DocType);
        DocDim.SETRANGE("Document No.", DocNo);
        DocDim.SETRANGE("Line No.", LineNo);
        IF NOT DocDim.ISEMPTY THEN
            DocDim.DELETEALL;
    end;

    procedure DeletePostedDocDim(TableID: Integer; DocNo: Code[20]; LineNo: Integer)
    var
        PostedDocDim: Record "359";
    begin
        PostedDocDim.SETRANGE("Table ID", TableID);
        PostedDocDim.SETRANGE("Document No.", DocNo);
        PostedDocDim.SETRANGE("Line No.", LineNo);
        IF NOT PostedDocDim.ISEMPTY THEN
            PostedDocDim.DELETEALL;
    end;

    procedure DeleteProdDocDim(TableID: Integer; DocStatus: Option; DocNo: Code[20]; DocLineNo: Integer; LineNo: Integer)
    var
        ProdDocDim: Record "358";
    begin
        ProdDocDim.SETRANGE("Table ID", TableID);
        ProdDocDim.SETRANGE("Document Status", DocStatus);
        ProdDocDim.SETRANGE("Document No.", DocNo);
        ProdDocDim.SETRANGE("Document Line No.", DocLineNo);
        ProdDocDim.SETRANGE("Line No.", LineNo);
        IF NOT ProdDocDim.ISEMPTY THEN
            ProdDocDim.DELETEALL;
    end;

    procedure DeleteServContractDim(TableId: Integer; Type: Option; ServContractNo: Code[20])
    var
        ServContractDim: Record "389";
    begin
        ServContractDim.SETRANGE("Table ID", TableId);
        ServContractDim.SETRANGE(Type, Type);
        ServContractDim.SETRANGE("No.", ServContractNo);
        IF NOT ServContractDim.ISEMPTY THEN
            ServContractDim.DELETEALL;
    end;

    procedure LookupDimValueCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimVal: Record "349";
        GLSetup: Record "General Ledger Setup";
    begin
        GetGLSetup;
        IF GLSetupShortcutDimCode[FieldNumber] = '' THEN
            ERROR(Text002, GLSetup.TABLECAPTION);
        DimVal.SETRANGE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        DimVal."Dimension Code" := GLSetupShortcutDimCode[FieldNumber];
        DimVal.Code := ShortcutDimCode;
        IF FORM.RUNMODAL(0, DimVal) = ACTION::LookupOK THEN BEGIN
            CheckDim(DimVal."Dimension Code");
            CheckDimValue(DimVal."Dimension Code", DimVal.Code);
            ShortcutDimCode := DimVal.Code;
        END;
    end;

    procedure ValidateDimValueCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    var
        DimVal: Record "349";
        GLSetup: Record "General Ledger Setup";
    begin
        GetGLSetup;
        IF (GLSetupShortcutDimCode[FieldNumber] = '') AND (ShortcutDimCode <> '') THEN
            ERROR(Text002, GLSetup.TABLECAPTION);
        DimVal.SETRANGE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        IF ShortcutDimCode <> '' THEN BEGIN
            DimVal.SETRANGE(Code, ShortcutDimCode);
            IF NOT DimVal.FINDFIRST THEN BEGIN
                DimVal.SETFILTER(Code, STRSUBSTNO('%1*', ShortcutDimCode));
                IF DimVal.FINDFIRST THEN
                    ShortcutDimCode := DimVal.Code
                ELSE
                    ERROR(
                      STRSUBSTNO(Text003,
                      ShortcutDimCode, DimVal.FIELDCAPTION(Code)));
            END;
        END;
    end;

    procedure SaveDefaultDim(TableID: Integer; No: Code[20]; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        DefaultDim: Record "352";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        IF ShortcutDimCode <> '' THEN BEGIN
            IF DefaultDim.GET(TableID, No, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                xRecRef.GETTABLE(DefaultDim);
                DefaultDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                DefaultDim.MODIFY;
                RecRef.GETTABLE(DefaultDim);
                ChangeLogMgt.LogModification(RecRef, xRecRef);
            END ELSE BEGIN
                DefaultDim.INIT;
                DefaultDim.VALIDATE("Table ID", TableID);
                DefaultDim.VALIDATE("No.", No);
                DefaultDim.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                DefaultDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                DefaultDim.INSERT;
                RecRef.GETTABLE(DefaultDim);
                ChangeLogMgt.LogInsertion(RecRef);
            END;
        END ELSE
            IF DefaultDim.GET(TableID, No, GLSetupShortcutDimCode[FieldNumber]) THEN BEGIN
                RecRef.GETTABLE(DefaultDim);
                DefaultDim.DELETE;
                ChangeLogMgt.LogDeletion(RecRef)
            END;
    end;

    procedure ShowJnlLineDim(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer; var ShortcutDimCode: array[8] of Code[20])
    var
        JnlLineDim: Record "Gen. Journal Line Dimension";
        i: Integer;
    begin
        GetGLSetup;
        FOR i := 3 TO 8 DO BEGIN
            ShortcutDimCode[i] := '';
            IF GLSetupShortcutDimCode[i] <> '' THEN
                IF JnlLineDim.GET(
                     TableID, JnlTemplateName, JnlBatchName,
                     JnlLineNo, AllocationLineNo, GLSetupShortcutDimCode[i])
                THEN
                    ShortcutDimCode[i] := JnlLineDim."Dimension Value Code";
        END;
    end;

    procedure SaveJnlLineDim(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        JnlLineDim: Record "Gen. Journal Line Dimension";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        IF ShortcutDimCode <> '' THEN BEGIN
            IF JnlLineDim.GET(
              TableID, JnlTemplateName, JnlBatchName,
              JnlLineNo, AllocationLineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                xRecRef.GETTABLE(JnlLineDim);
                JnlLineDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                JnlLineDim.MODIFY;
                RecRef.GETTABLE(JnlLineDim);
                ChangeLogMgt.LogModification(RecRef, xRecRef);
            END ELSE BEGIN
                JnlLineDim.INIT;
                JnlLineDim.VALIDATE("Table ID", TableID);
                JnlLineDim.VALIDATE("Journal Template Name", JnlTemplateName);
                JnlLineDim.VALIDATE("Journal Batch Name", JnlBatchName);
                JnlLineDim.VALIDATE("Journal Line No.", JnlLineNo);
                JnlLineDim.VALIDATE("Allocation Line No.", AllocationLineNo);
                JnlLineDim.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                JnlLineDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                JnlLineDim.INSERT;
                RecRef.GETTABLE(JnlLineDim);
                ChangeLogMgt.LogInsertion(RecRef);
            END;
        END ELSE
            IF JnlLineDim.GET(
              TableID, JnlTemplateName, JnlBatchName,
              JnlLineNo, AllocationLineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN
                IF JnlLineDim."New Dimension Value Code" = '' THEN BEGIN
                    RecRef.GETTABLE(JnlLineDim);
                    JnlLineDim.DELETE;
                    ChangeLogMgt.LogDeletion(RecRef);
                END ELSE BEGIN
                    xRecRef.GETTABLE(JnlLineDim);
                    JnlLineDim."Dimension Value Code" := '';
                    JnlLineDim.MODIFY;
                    RecRef.GETTABLE(JnlLineDim);
                    ChangeLogMgt.LogModification(RecRef, xRecRef);
                END;
    end;

    procedure ShowJnlLineNewDim(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer; var ShortcutNewDimCode: array[8] of Code[20])
    var
        JnlLineDim: Record "Gen. Journal Line Dimension";
        i: Integer;
    begin
        GetGLSetup;
        FOR i := 3 TO 8 DO BEGIN
            ShortcutNewDimCode[i] := '';
            IF GLSetupShortcutDimCode[i] <> '' THEN
                IF JnlLineDim.GET(
                     TableID, JnlTemplateName, JnlBatchName,
                     JnlLineNo, AllocationLineNo, GLSetupShortcutDimCode[i])
                THEN
                    ShortcutNewDimCode[i] := JnlLineDim."New Dimension Value Code";
        END;
    end;

    procedure SaveJnlLineNewDim(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer; FieldNumber: Integer; ShortcutNewDimCode: Code[20])
    var
        JnlLineDim: Record "Gen. Journal Line Dimension";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        IF ShortcutNewDimCode <> '' THEN BEGIN
            IF JnlLineDim.GET(
              TableID, JnlTemplateName, JnlBatchName,
              JnlLineNo, AllocationLineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                xRecRef.GETTABLE(JnlLineDim);
                JnlLineDim.VALIDATE("New Dimension Value Code", ShortcutNewDimCode);
                JnlLineDim.MODIFY;
                RecRef.GETTABLE(JnlLineDim);
                ChangeLogMgt.LogModification(RecRef, xRecRef);
            END ELSE BEGIN
                JnlLineDim.INIT;
                JnlLineDim.VALIDATE("Table ID", TableID);
                JnlLineDim.VALIDATE("Journal Template Name", JnlTemplateName);
                JnlLineDim.VALIDATE("Journal Batch Name", JnlBatchName);
                JnlLineDim.VALIDATE("Journal Line No.", JnlLineNo);
                JnlLineDim.VALIDATE("Allocation Line No.", AllocationLineNo);
                JnlLineDim.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                JnlLineDim.VALIDATE("New Dimension Value Code", ShortcutNewDimCode);
                JnlLineDim.INSERT;
                RecRef.GETTABLE(JnlLineDim);
                ChangeLogMgt.LogInsertion(RecRef);
            END;
        END ELSE
            IF JnlLineDim.GET(
              TableID, JnlTemplateName, JnlBatchName,
              JnlLineNo, AllocationLineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN
                IF JnlLineDim."Dimension Value Code" = '' THEN BEGIN
                    RecRef.GETTABLE(JnlLineDim);
                    JnlLineDim.DELETE;
                    ChangeLogMgt.LogDeletion(RecRef);
                END ELSE BEGIN
                    xRecRef.GETTABLE(JnlLineDim);
                    JnlLineDim."New Dimension Value Code" := '';
                    JnlLineDim.MODIFY;
                    RecRef.GETTABLE(JnlLineDim);
                    ChangeLogMgt.LogModification(RecRef, xRecRef);
                END;
    end;

    procedure ShowDocDim(TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer; var ShortcutDimCode: array[8] of Code[20])
    var
        DocDim: Record "Document Dimension";
        i: Integer;
    begin
        GetGLSetup;
        FOR i := 3 TO 8 DO BEGIN
            ShortcutDimCode[i] := '';
            IF GLSetupShortcutDimCode[i] <> '' THEN
                IF DocDim.GET(TableID, DocType, DocNo, LineNo, GLSetupShortcutDimCode[i]) THEN
                    ShortcutDimCode[i] := DocDim."Dimension Value Code";
        END;
    end;

    procedure SaveDocDim(TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        DocDim: Record "Document Dimension";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        IF ShortcutDimCode <> '' THEN BEGIN
            IF DocDim.GET(
              TableID, DocType, DocNo,
              LineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                xRecRef.GETTABLE(DocDim);
                DocDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                DocDim.UpdateLineDim(DocDim, FALSE);
                DocDim.MODIFY;
                RecRef.GETTABLE(DocDim);
                ChangeLogMgt.LogModification(RecRef, xRecRef);
            END ELSE BEGIN
                DocDim.INIT;
                DocDim.VALIDATE("Table ID", TableID);
                DocDim.VALIDATE("Document Type", DocType);
                DocDim.VALIDATE("Document No.", DocNo);
                DocDim.VALIDATE("Line No.", LineNo);
                DocDim.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                DocDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                DocDim.UpdateLineDim(DocDim, FALSE);
                DocDim.INSERT;
                RecRef.GETTABLE(DocDim);
                ChangeLogMgt.LogInsertion(RecRef);
            END;
        END ELSE
            IF DocDim.GET(
              TableID, DocType, DocNo, LineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                RecRef.GETTABLE(DocDim);
                DocDim.UpdateLineDim(DocDim, TRUE);
                DocDim.DELETE;
                ChangeLogMgt.LogDeletion(RecRef);
            END;
    end;

    procedure ShowProdDocDim(TableID: Integer; DocStatus: Option; DocNo: Code[20]; DocLineNo: Integer; LineNo: Integer; var ShortcutDimCode: array[8] of Code[20])
    var
        ProdDocDim: Record "358";
        i: Integer;
    begin
        GetGLSetup;
        FOR i := 3 TO 8 DO BEGIN
            ShortcutDimCode[i] := '';
            IF GLSetupShortcutDimCode[i] <> '' THEN
                IF ProdDocDim.GET(TableID, DocStatus, DocNo, DocLineNo, LineNo, GLSetupShortcutDimCode[i]) THEN
                    ShortcutDimCode[i] := ProdDocDim."Dimension Value Code";
        END;
    end;

    procedure SaveProdDocDim(TableID: Integer; DocStatus: Option; DocNo: Code[20]; DocLineNo: Integer; LineNo: Integer; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        ProdDocDim: Record "358";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        IF ShortcutDimCode <> '' THEN BEGIN
            IF ProdDocDim.GET(
              TableID, DocStatus, DocNo,
              DocLineNo, LineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                xRecRef.GETTABLE(ProdDocDim);
                ProdDocDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                ProdDocDim.UpdateLineDim(ProdDocDim, FALSE);
                ProdDocDim.MODIFY;
                RecRef.GETTABLE(ProdDocDim);
                ChangeLogMgt.LogModification(RecRef, xRecRef);
            END ELSE BEGIN
                ProdDocDim.INIT;
                ProdDocDim.VALIDATE("Table ID", TableID);
                ProdDocDim.VALIDATE("Document Status", DocStatus);
                ProdDocDim.VALIDATE("Document No.", DocNo);
                ProdDocDim.VALIDATE("Document Line No.", DocLineNo);
                ProdDocDim.VALIDATE("Line No.", LineNo);
                ProdDocDim.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                ProdDocDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                ProdDocDim.UpdateLineDim(ProdDocDim, FALSE);
                ProdDocDim.INSERT;
                RecRef.GETTABLE(ProdDocDim);
                ChangeLogMgt.LogInsertion(RecRef);
            END;
        END ELSE
            IF ProdDocDim.GET(
              TableID, DocStatus, DocNo,
              DocLineNo, LineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                RecRef.GETTABLE(ProdDocDim);
                ProdDocDim.UpdateLineDim(ProdDocDim, TRUE);
                ProdDocDim.DELETE;
                ChangeLogMgt.LogDeletion(RecRef);
            END;
    end;

    procedure ShowTempDim(var ShortcutDimCode: array[8] of Code[20])
    var
        i: Integer;
    begin
        GetGLSetup;
        FOR i := 3 TO 8 DO BEGIN
            ShortcutDimCode[i] := '';
            IF GLSetupShortcutDimCode[i] <> '' THEN BEGIN
                TempDimBuf2.SETRANGE("Dimension Code", GLSetupShortcutDimCode[i]);
                IF TempDimBuf2.FINDFIRST THEN
                    ShortcutDimCode[i] := TempDimBuf2."Dimension Value Code";
            END;
        END;
        TempDimBuf2.RESET;
    end;

    procedure SaveTempDim(FieldNumber: Integer; ShortcutDimCode: Code[20])
    begin
        GetGLSetup;
        TempDimBuf2.SETRANGE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        IF ShortcutDimCode <> '' THEN BEGIN
            IF TempDimBuf2.FINDFIRST THEN BEGIN
                TempDimBuf2.VALIDATE("Dimension Value Code", ShortcutDimCode);
                TempDimBuf2.MODIFY;
            END ELSE BEGIN
                TempDimBuf2.INIT;
                TempDimBuf2.VALIDATE("Table ID", 0);
                TempDimBuf2.VALIDATE("Entry No.", 0);
                TempDimBuf2.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                TempDimBuf2.VALIDATE("Dimension Value Code", ShortcutDimCode);
                TempDimBuf2.INSERT;
            END;
        END ELSE
            IF TempDimBuf2.FINDFIRST THEN
                IF TempDimBuf2."New Dimension Value Code" = '' THEN
                    TempDimBuf2.DELETE
                ELSE BEGIN
                    TempDimBuf2."Dimension Value Code" := '';
                    TempDimBuf2.MODIFY;
                END;
        TempDimBuf2.RESET;
    end;

    procedure ShowTempNewDim(var ShortcutNewDimCode: array[8] of Code[20])
    var
        i: Integer;
    begin
        GetGLSetup;
        FOR i := 3 TO 8 DO BEGIN
            ShortcutNewDimCode[i] := '';
            IF GLSetupShortcutDimCode[i] <> '' THEN BEGIN
                TempDimBuf2.SETRANGE("Dimension Code", GLSetupShortcutDimCode[i]);
                IF TempDimBuf2.FINDFIRST THEN
                    ShortcutNewDimCode[i] := TempDimBuf2."New Dimension Value Code";
            END;
        END;
        TempDimBuf2.RESET;
    end;

    procedure SaveTempNewDim(FieldNumber: Integer; ShortcutNewDimCode: Code[20])
    begin
        GetGLSetup;
        TempDimBuf2.SETRANGE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        IF ShortcutNewDimCode <> '' THEN BEGIN
            IF TempDimBuf2.FINDFIRST THEN BEGIN
                TempDimBuf2.VALIDATE("New Dimension Value Code", ShortcutNewDimCode);
                TempDimBuf2.MODIFY;
            END ELSE BEGIN
                TempDimBuf2.INIT;
                TempDimBuf2.VALIDATE("Table ID", 0);
                TempDimBuf2.VALIDATE("Entry No.", 0);
                TempDimBuf2.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                TempDimBuf2.VALIDATE("New Dimension Value Code", ShortcutNewDimCode);
                TempDimBuf2.INSERT;
            END;
        END ELSE
            IF TempDimBuf2.FINDFIRST THEN
                IF TempDimBuf2."Dimension Value Code" = '' THEN
                    TempDimBuf2.DELETE
                ELSE BEGIN
                    TempDimBuf2."New Dimension Value Code" := '';
                    TempDimBuf2.MODIFY;
                END;
        TempDimBuf2.RESET;
    end;

    procedure SaveServContractDim(TableID: Integer; Type: Option; No: Code[20]; LineNo: Integer; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        ServContrDim: Record "389";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        IF ShortcutDimCode <> '' THEN BEGIN
            IF ServContrDim.GET(
              TableID, Type, No,
              LineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                xRecRef.GETTABLE(ServContrDim);
                ServContrDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                ServContrDim.MODIFY;
                RecRef.GETTABLE(ServContrDim);
                ChangeLogMgt.LogModification(RecRef, xRecRef);
            END ELSE BEGIN
                ServContrDim.INIT;
                ServContrDim.VALIDATE("Table ID", TableID);
                ServContrDim.VALIDATE(Type, Type);
                ServContrDim.VALIDATE("No.", No);
                ServContrDim.VALIDATE("Line No.", LineNo);
                ServContrDim.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                ServContrDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                ServContrDim.INSERT;
                RecRef.GETTABLE(ServContrDim);
                ChangeLogMgt.LogInsertion(RecRef);
            END;
        END ELSE
            IF ServContrDim.GET(
              TableID, Type, No, LineNo, GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                RecRef.GETTABLE(ServContrDim);
                ServContrDim.DELETE;
                ChangeLogMgt.LogDeletion(RecRef);
            END;
    end;

    procedure CheckDimBufferValuePosting(var DimBuffer: Record "Dimension Buffer"; TableID: array[10] of Integer; No: array[10] of Code[20]): Boolean
    var
        i: Integer;
    begin
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF DimBuffer.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                IF (NOT CheckDimValue(
                  DimBuffer."Dimension Code", DimBuffer."Dimension Value Code")) OR
                  (NOT CheckDim(DimBuffer."Dimension Code"))
                THEN BEGIN
                    DimValuePostingErr := DimErr;
                    EXIT(FALSE);
                END;
                TempDimBuf2.INIT;
                TempDimBuf2."Table ID" := DATABASE::"Document Dimension";
                TempDimBuf2."Entry No." := i;
                TempDimBuf2."Dimension Code" := DimBuffer."Dimension Code";
                TempDimBuf2."Dimension Value Code" := DimBuffer."Dimension Value Code";
                TempDimBuf2.INSERT;
                i := i + 1;
            UNTIL DimBuffer.NEXT = 0;
        END;
        EXIT(CheckValuePosting(TableID, No));
    end;

    procedure CheckJnlLineDimValuePosting(var JnlLineDim: Record "Gen. Journal Line Dimension"; TableID: array[10] of Integer; No: array[10] of Code[20]): Boolean
    var
        i: Integer;
    begin
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF JnlLineDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                IF (NOT CheckDimValue(JnlLineDim."Dimension Code", JnlLineDim."Dimension Value Code")) OR
                  (NOT CheckDim(JnlLineDim."Dimension Code"))
                THEN BEGIN
                    DimValuePostingErr := DimErr;
                    EXIT(FALSE);
                END;
                TempDimBuf2.INIT;
                TempDimBuf2."Table ID" := DATABASE::"Journal Line Dimension";
                TempDimBuf2."Dimension Code" := JnlLineDim."Dimension Code";
                IF JnlLineDim."Dimension Value Code" <> '' THEN BEGIN
                    TempDimBuf2."Entry No." := i;
                    TempDimBuf2."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                    TempDimBuf2.INSERT;
                    i := i + 1;
                END;
                IF JnlLineDim."New Dimension Value Code" <> '' THEN BEGIN
                    TempDimBuf2."Entry No." := i;
                    TempDimBuf2."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                    TempDimBuf2.INSERT;
                    i := i + 1;
                END;
            UNTIL JnlLineDim.NEXT = 0;
        END;
        EXIT(CheckValuePosting(TableID, No));
    end;

    procedure CheckJnlLineNewDimValuePosting(var JnlLineDim: Record "Gen. Journal Line Dimension"; TableID: array[10] of Integer; No: array[10] of Code[20]): Boolean
    var
        i: Integer;
    begin
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF JnlLineDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                IF (NOT CheckDimValue(JnlLineDim."Dimension Code", JnlLineDim."New Dimension Value Code")) OR
                  (NOT CheckDim(JnlLineDim."Dimension Code"))
                THEN BEGIN
                    DimValuePostingErr := DimErr;
                    EXIT(FALSE);
                END;
                TempDimBuf2.INIT;
                TempDimBuf2."Table ID" := DATABASE::"Journal Line Dimension";
                TempDimBuf2."Dimension Code" := JnlLineDim."Dimension Code";
                IF JnlLineDim."New Dimension Value Code" <> '' THEN BEGIN
                    TempDimBuf2."Entry No." := i;
                    TempDimBuf2."Dimension Value Code" := JnlLineDim."New Dimension Value Code";
                    TempDimBuf2.INSERT;
                    i := i + 1;
                END;
            UNTIL JnlLineDim.NEXT = 0;
        END;
        EXIT(CheckValuePosting(TableID, No));
    end;

    procedure CheckDocDimValuePosting(var DocDim: Record "Document Dimension"; TableID: array[10] of Integer; No: array[10] of Code[20]): Boolean
    var
        i: Integer;
    begin
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF DocDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                IF (NOT CheckDimValue(DocDim."Dimension Code", DocDim."Dimension Value Code")) OR
                  (NOT CheckDim(DocDim."Dimension Code"))
                THEN BEGIN
                    DimValuePostingErr := DimErr;
                    EXIT(FALSE);
                END;
                TempDimBuf2.INIT;
                TempDimBuf2."Table ID" := DATABASE::"Document Dimension";
                TempDimBuf2."Entry No." := i;
                TempDimBuf2."Dimension Code" := DocDim."Dimension Code";
                TempDimBuf2."Dimension Value Code" := DocDim."Dimension Value Code";
                TempDimBuf2.INSERT;
                i := i + 1;
            UNTIL DocDim.NEXT = 0;
        END;
        EXIT(CheckValuePosting(TableID, No));
    end;

    procedure CheckServContrDimValuePosting(var ServContractDim: Record "389"; TableID: array[10] of Integer; No: array[10] of Code[20]): Boolean
    var
        i: Integer;
    begin
        TempDimBuf2.RESET;
        TempDimBuf2.DELETEALL;
        IF ServContractDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                IF (NOT CheckDimValue(ServContractDim."Dimension Code", ServContractDim."Dimension Value Code")) OR
                  (NOT CheckDim(ServContractDim."Dimension Code"))
                THEN BEGIN
                    DimValuePostingErr := DimErr;
                    EXIT(FALSE);
                END;
                TempDimBuf2.INIT;
                TempDimBuf2."Table ID" := DATABASE::"Service Contract Dimension";
                TempDimBuf2."Entry No." := i;
                TempDimBuf2."Dimension Code" := ServContractDim."Dimension Code";
                TempDimBuf2."Dimension Value Code" := ServContractDim."Dimension Value Code";
                TempDimBuf2.INSERT;
                i := i + 1;
            UNTIL ServContractDim.NEXT = 0;
        END;
        EXIT(CheckValuePosting(TableID, No));
    end;

    local procedure CheckValuePosting(TableID: array[10] of Integer; No: array[10] of Code[20]): Boolean
    var
        DefaultDim: Record "352";
        i: Integer;
        j: Integer;
        NoFilter: array[2] of Text[250];
    begin
        DefaultDim.SETFILTER("Value Posting", '<>%1', DefaultDim."Value Posting"::" ");
        NoFilter[2] := '';
        FOR i := 1 TO ARRAYLEN(TableID) DO BEGIN
            IF (TableID[i] <> 0) AND (No[i] <> '') THEN BEGIN
                DefaultDim.SETRANGE("Table ID", TableID[i]);
                NoFilter[1] := No[i];
                FOR j := 1 TO 2 DO BEGIN
                    DefaultDim.SETRANGE("No.", NoFilter[j]);
                    IF DefaultDim.FINDSET THEN BEGIN
                        REPEAT
                            TempDimBuf2.SETRANGE("Dimension Code", DefaultDim."Dimension Code");
                            CASE DefaultDim."Value Posting" OF
                                DefaultDim."Value Posting"::"Code Mandatory":
                                    BEGIN
                                        IF (NOT TempDimBuf2.FINDFIRST) OR
                                             (TempDimBuf2."Dimension Value Code" = '')
                                        THEN BEGIN
                                            IF DefaultDim."No." = '' THEN
                                                DimValuePostingErr :=
                                                  STRSUBSTNO(
                                                    Text004,
                                                    DefaultDim.FIELDCAPTION("Dimension Value Code"),
                                                    DefaultDim.FIELDCAPTION("Dimension Code"), DefaultDim."Dimension Code")
                                            ELSE
                                                DimValuePostingErr :=
                                                  STRSUBSTNO(
                                                    Text005,
                                                    DefaultDim.FIELDCAPTION("Dimension Value Code"),
                                                    DefaultDim.FIELDCAPTION("Dimension Code"),
                                                    DefaultDim."Dimension Code",
                                                    ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DefaultDim."Table ID"),
                                                    DefaultDim."No.");
                                            EXIT(FALSE);
                                        END;
                                    END;
                                DefaultDim."Value Posting"::"Same Code":
                                    BEGIN
                                        IF (DefaultDim."Dimension Value Code" <> '') THEN BEGIN
                                            IF (NOT TempDimBuf2.FINDFIRST) OR
                                              (DefaultDim."Dimension Value Code" <> TempDimBuf2."Dimension Value Code")
                                            THEN BEGIN
                                                IF DefaultDim."No." = '' THEN
                                                    DimValuePostingErr :=
                                                      STRSUBSTNO(
                                                        Text006,
                                                        DefaultDim.FIELDCAPTION("Dimension Value Code"), DefaultDim."Dimension Value Code",
                                                        DefaultDim.FIELDCAPTION("Dimension Code"), DefaultDim."Dimension Code")
                                                ELSE
                                                    DimValuePostingErr :=
                                                      STRSUBSTNO(
                                                        Text007,
                                                        DefaultDim.FIELDCAPTION("Dimension Value Code"),
                                                        DefaultDim."Dimension Value Code",
                                                        DefaultDim.FIELDCAPTION("Dimension Code"),
                                                        DefaultDim."Dimension Code",
                                                        ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DefaultDim."Table ID"),
                                                        DefaultDim."No.");
                                                EXIT(FALSE);
                                            END;
                                        END ELSE BEGIN
                                            IF TempDimBuf2.FINDFIRST THEN BEGIN
                                                IF DefaultDim."No." = '' THEN
                                                    DimValuePostingErr :=
                                                      STRSUBSTNO(
                                                        Text008,
                                                        TempDimBuf2.FIELDCAPTION("Dimension Code"), TempDimBuf2."Dimension Code")
                                                ELSE
                                                    DimValuePostingErr :=
                                                      STRSUBSTNO(
                                                        Text009,
                                                        TempDimBuf2.FIELDCAPTION("Dimension Code"),
                                                        TempDimBuf2."Dimension Code",
                                                        ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DefaultDim."Table ID"),
                                                        DefaultDim."No.");
                                                EXIT(FALSE);
                                            END;
                                        END;
                                    END;
                                DefaultDim."Value Posting"::"No Code":
                                    BEGIN
                                        IF TempDimBuf2.FINDFIRST THEN BEGIN
                                            IF DefaultDim."No." = '' THEN
                                                DimValuePostingErr :=
                                                  STRSUBSTNO(
                                                    Text010,
                                                    TempDimBuf2.FIELDCAPTION("Dimension Code"), TempDimBuf2."Dimension Code")
                                            ELSE
                                                DimValuePostingErr :=
                                                  STRSUBSTNO(
                                                    Text011,
                                                    TempDimBuf2.FIELDCAPTION("Dimension Code"),
                                                    TempDimBuf2."Dimension Code",
                                                    ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DefaultDim."Table ID"),
                                                    DefaultDim."No.");
                                            EXIT(FALSE);
                                        END;
                                    END;
                            END;
                        UNTIL DefaultDim.NEXT = 0;
                        TempDimBuf2.RESET;
                    END;
                END;
            END;
        END;
        EXIT(TRUE);
    end;

    procedure GetDimValuePostingErr(): Text[250]
    begin
        EXIT(DimValuePostingErr);
    end;

    procedure SetupObjectNoList(var TempObject: Record "2000000001" temporary)
    var
        "Object": Record "2000000001";
        TableIDArray: array[29] of Integer;
        Index: Integer;
    begin
        TableIDArray[1] := DATABASE::"Salesperson/Purchaser";
        TableIDArray[2] := DATABASE::"G/L Account";
        TableIDArray[3] := DATABASE::Customer;
        TableIDArray[4] := DATABASE::Vendor;
        TableIDArray[5] := DATABASE::Item;
        TableIDArray[6] := DATABASE::"Resource Group";
        TableIDArray[7] := DATABASE::Resource;
        TableIDArray[8] := DATABASE::Job;
        TableIDArray[9] := DATABASE::"Bank Account";
        TableIDArray[10] := DATABASE::Campaign;
        TableIDArray[11] := DATABASE::Employee;
        TableIDArray[12] := DATABASE::"Fixed Asset";
        TableIDArray[13] := DATABASE::Insurance;
        TableIDArray[14] := DATABASE::"Responsibility Center";
        TableIDArray[15] := DATABASE::"Item Charge";
        TableIDArray[16] := DATABASE::"Work Center";
        TableIDArray[17] := DATABASE::"Service Contract Header";
        TableIDArray[18] := DATABASE::"Customer Template";
        TableIDArray[19] := DATABASE::"Service Contract Template";
        TableIDArray[20] := DATABASE::"IC Partner";
        TableIDArray[21] := DATABASE::"Service Order Type";
        TableIDArray[22] := DATABASE::"Service Item Group";
        TableIDArray[23] := DATABASE::"Service Item";
        //LS -
        TableIDArray[24] := DATABASE::Store;
        //LS +
        //DP6.01.01 START
        TableIDArray[25] := DATABASE::Premise;
        TableIDArray[26] := DATABASE::Facility;
        TableIDArray[27] := DATABASE::"Event Detail";
        TableIDArray[28] := DATABASE::"Sales Representative";
        TableIDArray[29] := DATABASE::"Agreement Element"; //DP6.01.02
        //DP6.01.01 STOP


        Object.SETRANGE(Type, Object.Type::Table);

        FOR Index := 1 TO ARRAYLEN(TableIDArray) DO BEGIN
            Object.SETRANGE(Object.ID, TableIDArray[Index]);
            IF Object.FINDFIRST THEN BEGIN
                TempObject := Object;
                TempObject.INSERT;
            END;
        END;
    end;

    procedure MoveJnlLineDimToLedgEntryDim(var JnlLineDim: Record "Gen. Journal Line Dimension"; ToTableID: Integer; ToEntryNo: Integer)
    var
        LedgEntryDim: Record "355";
    begin
        WITH JnlLineDim DO
            IF FINDSET THEN
                REPEAT
                    LedgEntryDim.INIT;
                    LedgEntryDim."Table ID" := ToTableID;
                    LedgEntryDim."Entry No." := ToEntryNo;
                    LedgEntryDim."Dimension Code" := "Dimension Code";
                    LedgEntryDim."Dimension Value Code" := "Dimension Value Code";
                    LedgEntryDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveDocDimToPostedDocDim(var DocDim: Record "Document Dimension"; ToTableID: Integer; ToNo: Code[20])
    var
        PostedDocDim: Record "359";
    begin
        WITH DocDim DO
            IF FINDSET THEN
                REPEAT
                    PostedDocDim.INIT;
                    PostedDocDim."Table ID" := ToTableID;
                    PostedDocDim."Document No." := ToNo;
                    PostedDocDim."Line No." := "Line No.";
                    PostedDocDim."Dimension Code" := "Dimension Code";
                    PostedDocDim."Dimension Value Code" := "Dimension Value Code";
                    PostedDocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveOneDocDimToPostedDocDim(var FromDocDim: Record "Document Dimension"; FromTableID: Integer; FromDocType: Integer; FromDocNo: Code[20]; FromLineNo: Integer; ToTableID: Integer; ToDocNo: Code[20])
    var
        ToPostedDocDim: Record "359";
    begin
        WITH FromDocDim DO BEGIN
            SETRANGE("Table ID", FromTableID);
            SETRANGE("Document Type", FromDocType);
            SETRANGE("Document No.", FromDocNo);
            SETRANGE("Line No.", FromLineNo);
            IF FINDSET THEN
                REPEAT
                    ToPostedDocDim.INIT;
                    ToPostedDocDim."Table ID" := ToTableID;
                    ToPostedDocDim."Document No." := ToDocNo;
                    ToPostedDocDim."Line No." := "Line No.";
                    ToPostedDocDim."Dimension Code" := "Dimension Code";
                    ToPostedDocDim."Dimension Value Code" := "Dimension Value Code";
                    ToPostedDocDim.INSERT;
                UNTIL NEXT = 0;
        END;
    end;

    procedure MoveLedgEntryDimToJnlLineDim(var FromLedgEntryDim: Record "355"; var ToJnlLineDim: Record "Gen. Journal Line Dimension"; ToTableID: Integer; ToJnlTemplateName: Code[10]; ToJnlBatchName: Code[10]; ToJnlLineNo: Integer; ToAllocLineNo: Integer)
    begin
        WITH FromLedgEntryDim DO
            IF FINDSET THEN
                REPEAT
                    ToJnlLineDim."Table ID" := ToTableID;
                    ToJnlLineDim."Journal Template Name" := ToJnlTemplateName;
                    ToJnlLineDim."Journal Batch Name" := ToJnlBatchName;
                    ToJnlLineDim."Journal Line No." := ToJnlLineNo;
                    ToJnlLineDim."Allocation Line No." := ToAllocLineNo;
                    ToJnlLineDim."Dimension Code" := "Dimension Code";
                    ToJnlLineDim."Dimension Value Code" := "Dimension Value Code";
                    ToJnlLineDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveDimBufToJnlLineDim(var FromDimBuf: Record "Dimension Buffer"; var ToJnlLineDim: Record "Gen. Journal Line Dimension"; TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer)
    begin
        WITH FromDimBuf DO
            IF FINDSET THEN
                REPEAT
                    ToJnlLineDim."Table ID" := TableID;
                    ToJnlLineDim."Journal Template Name" := JnlTemplateName;
                    ToJnlLineDim."Journal Batch Name" := JnlBatchName;
                    ToJnlLineDim."Journal Line No." := JnlLineNo;
                    ToJnlLineDim."Dimension Code" := "Dimension Code";
                    ToJnlLineDim."Dimension Value Code" := "Dimension Value Code";
                    ToJnlLineDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveDimBufToLedgEntryDim(var FromDimBuf: Record "Dimension Buffer"; ToTableID: Integer; ToEntryNo: Integer)
    var
        LedgEntryDim: Record "355";
    begin
        WITH FromDimBuf DO
            IF FINDSET THEN
                REPEAT
                    LedgEntryDim."Table ID" := ToTableID;
                    LedgEntryDim."Entry No." := ToEntryNo;
                    LedgEntryDim."Dimension Code" := "Dimension Code";
                    LedgEntryDim."Dimension Value Code" := "Dimension Value Code";
                    LedgEntryDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveDimBufToPostedDocDim(var FromDimBuf: Record "Dimension Buffer"; ToTableID: Integer; ToDocNo: Code[20]; ToLineNo: Integer)
    var
        PostedDocDim: Record "359";
    begin
        WITH FromDimBuf DO
            IF FIND('-') THEN
                REPEAT
                    PostedDocDim."Table ID" := ToTableID;
                    PostedDocDim."Document No." := ToDocNo;
                    PostedDocDim."Line No." := ToLineNo;
                    PostedDocDim."Dimension Code" := "Dimension Code";
                    PostedDocDim."Dimension Value Code" := "Dimension Value Code";
                    PostedDocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveDimBufToGLBudgetDim(var FromDimBuf: Record "Dimension Buffer"; ToEntryNo: Integer)
    var
        GLBudgetDim: Record "361";
    begin
        WITH FromDimBuf DO
            IF FINDSET THEN
                REPEAT
                    GLBudgetDim."Entry No." := ToEntryNo;
                    GLBudgetDim."Dimension Code" := "Dimension Code";
                    GLBudgetDim."Dimension Value Code" := "Dimension Value Code";
                    GLBudgetDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CopyJnlLineDimToJnlLineDim(var FromJnlLineDim: Record "Gen. Journal Line Dimension"; var ToJnlLineDim: Record "Gen. Journal Line Dimension"): Boolean
    begin
        DimensionChanged := FALSE;
        IF FromJnlLineDim.FINDSET THEN
            REPEAT
                ToJnlLineDim := FromJnlLineDim;
                ToJnlLineDim.INSERT;
                IF NOT DimensionChanged THEN
                    DimensionChanged :=
                      ToJnlLineDim."Dimension Value Code" <> ToJnlLineDim."New Dimension Value Code";
            UNTIL FromJnlLineDim.NEXT = 0;
        EXIT(DimensionChanged);
    end;

    procedure CopyLedgEntryDimToJnlLineDim(var FromLedgEntryDim: Record "355"; var ToJnlLineDim: Record "Gen. Journal Line Dimension")
    begin
        WITH FromLedgEntryDim DO
            IF FINDSET THEN
                REPEAT
                    ToJnlLineDim."Table ID" := "Table ID";
                    ToJnlLineDim."Dimension Code" := "Dimension Code";
                    ToJnlLineDim."Dimension Value Code" := "Dimension Value Code";
                    ToJnlLineDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CopyDocDimToDocDim(var FromDocDim: Record "Document Dimension"; var ToDocDim: Record "Document Dimension")
    begin
        IF FromDocDim.FINDSET THEN
            REPEAT
                ToDocDim := FromDocDim;
                ToDocDim.INSERT;
            UNTIL FromDocDim.NEXT = 0;
    end;

    procedure CopyPostedDocDimToPostedDocDim(var FromPostedDocDim: Record "359"; var ToPostedDocDim: Record "359")
    begin
        IF FromPostedDocDim.FINDSET THEN
            REPEAT
                ToPostedDocDim := FromPostedDocDim;
                ToPostedDocDim.INSERT;
            UNTIL FromPostedDocDim.NEXT = 0;
    end;

    procedure CopyDocDimToJnlLineDim(var FromDocDim: Record "Document Dimension"; var ToJnlLineDim: Record "Gen. Journal Line Dimension")
    begin
        WITH FromDocDim DO
            IF FINDSET THEN
                REPEAT
                    ToJnlLineDim."Table ID" := "Table ID";
                    ToJnlLineDim."Dimension Code" := "Dimension Code";
                    ToJnlLineDim."Dimension Value Code" := "Dimension Value Code";
                    ToJnlLineDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CopyDimBufToJnlLineDim(var FromDimBuf: Record "Dimension Buffer"; var ToJnlLineDim: Record "Gen. Journal Line Dimension"; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer)
    begin
        WITH FromDimBuf DO
            IF FINDSET THEN
                REPEAT
                    ToJnlLineDim."Table ID" := "Table ID";
                    ToJnlLineDim."Journal Template Name" := JnlTemplateName;
                    ToJnlLineDim."Journal Batch Name" := JnlBatchName;
                    ToJnlLineDim."Journal Line No." := JnlLineNo;
                    ToJnlLineDim."Dimension Code" := "Dimension Code";
                    ToJnlLineDim."Dimension Value Code" := "Dimension Value Code";
                    ToJnlLineDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CopyDimBufToDocDim(var FromDimBuf: Record "Dimension Buffer"; ToTableID: Integer; ToDocNo: Code[20]; ToLineNo: Integer; var ToDocDim: Record "Document Dimension")
    begin
        WITH FromDimBuf DO
            IF FIND('-') THEN
                REPEAT
                    ToDocDim."Table ID" := ToTableID;
                    ToDocDim."Document No." := ToDocNo;
                    ToDocDim."Line No." := ToLineNo;
                    ToDocDim."Dimension Code" := "Dimension Code";
                    ToDocDim."Dimension Value Code" := "Dimension Value Code";
                    ToDocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CopySCDimToDocDim(var FromServContractDim: Record "389"; TableId: Integer; DocumentType: Option; DocumentNo: Code[20]; LineNo: Integer)
    var
        ToDocDim: Record "Document Dimension";
    begin
        WITH FromServContractDim DO
            IF FINDSET THEN
                REPEAT
                    ToDocDim."Table ID" := TableId;
                    ToDocDim."Document Type" := DocumentType;
                    ToDocDim."Document No." := DocumentNo;
                    ToDocDim."Line No." := LineNo;
                    ToDocDim."Dimension Code" := "Dimension Code";
                    ToDocDim."Dimension Value Code" := "Dimension Value Code";
                    ToDocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CheckDocDimConsistency(var DocDim: Record "Document Dimension"; var PostedDocDim: Record "359"; DocTableID: Integer; PostedDocTableID: Integer): Boolean
    begin
        IF DocDim.FINDSET THEN;
        IF PostedDocDim.FINDSET THEN;
        REPEAT
            CASE TRUE OF
                DocDim."Dimension Code" > PostedDocDim."Dimension Code":
                    BEGIN
                        DocDimConsistencyErr :=
                          STRSUBSTNO(
                            Text012,
                            DocDim.FIELDCAPTION("Dimension Code"),
                            ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DocTableID),
                            ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, PostedDocTableID));
                        EXIT(FALSE);
                    END;
                DocDim."Dimension Code" < PostedDocDim."Dimension Code":
                    BEGIN
                        DocDimConsistencyErr :=
                          STRSUBSTNO(
                            Text012,
                            PostedDocDim.FIELDCAPTION("Dimension Code"),
                            ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, PostedDocTableID),
                            ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DocTableID));
                        EXIT(FALSE);
                    END;
                DocDim."Dimension Code" = PostedDocDim."Dimension Code":
                    BEGIN
                        IF DocDim."Dimension Value Code" <> PostedDocDim."Dimension Value Code" THEN BEGIN
                            DocDimConsistencyErr :=
                              STRSUBSTNO(
                                Text013,
                                DocDim.FIELDCAPTION("Dimension Value Code"),
                                DocDim.FIELDCAPTION("Dimension Code"),
                                DocDim."Dimension Code",
                                ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, DocTableID),
                                ObjTransl.TranslateObject(ObjTransl."Object Type"::Table, PostedDocTableID));
                            EXIT(FALSE);
                        END;
                    END;
            END;
        UNTIL (DocDim.NEXT = 0) AND (PostedDocDim.NEXT = 0);
        EXIT(TRUE);
    end;

    procedure GetDocDimConsistencyErr(): Text[250]
    begin
        EXIT(DocDimConsistencyErr);
    end;

    procedure CheckDim(DimCode: Code[20]): Boolean
    var
        Dim: Record "348";
    begin
        IF Dim.GET(DimCode) THEN BEGIN
            IF Dim.Blocked THEN BEGIN
                DimErr :=
                  STRSUBSTNO(Text014, Dim.TABLECAPTION, DimCode);
                EXIT(FALSE);
            END;
        END ELSE BEGIN
            DimErr :=
              STRSUBSTNO(Text015, Dim.TABLECAPTION, DimCode);
            EXIT(FALSE);
        END;
        EXIT(TRUE);
    end;

    procedure CheckDimValue(DimCode: Code[20]; DimValCode: Code[20]): Boolean
    var
        DimVal: Record "349";
    begin
        IF (DimCode <> '') AND (DimValCode <> '') THEN BEGIN
            IF DimVal.GET(DimCode, DimValCode) THEN BEGIN
                IF DimVal.Blocked THEN BEGIN
                    DimErr :=
                      STRSUBSTNO(
                        Text016, DimVal.TABLECAPTION, DimCode, DimValCode);
                    EXIT(FALSE);
                END;
                IF NOT (DimVal."Dimension Value Type" IN
                  [DimVal."Dimension Value Type"::Standard,
                   DimVal."Dimension Value Type"::"Begin-Total"])
                THEN BEGIN
                    DimErr :=
                      STRSUBSTNO(Text017, DimVal.FIELDCAPTION("Dimension Value Type"),
                      DimVal.TABLECAPTION, DimCode, DimValCode, FORMAT(DimVal."Dimension Value Type"));
                    EXIT(FALSE);
                END;
            END ELSE BEGIN
                DimErr :=
                  STRSUBSTNO(
                    Text018, DimVal.TABLECAPTION, DimCode);
                EXIT(FALSE);
            END;
        END;
        EXIT(TRUE);
    end;

    procedure GetDimErr(): Text[250]
    begin
        EXIT(DimErr);
    end;

    procedure MoveDocDimToLedgEntryDim(var DocDim: Record "Document Dimension"; ToTableID: Integer; ToEntryNo: Integer)
    var
        LedgEntryDim: Record "355";
    begin
        WITH DocDim DO
            IF FINDSET THEN
                REPEAT
                    LedgEntryDim.INIT;
                    LedgEntryDim."Table ID" := ToTableID;
                    LedgEntryDim."Entry No." := ToEntryNo;
                    LedgEntryDim."Dimension Code" := "Dimension Code";
                    LedgEntryDim."Dimension Value Code" := "Dimension Value Code";
                    LedgEntryDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveDocDimToDocDim(var FromDocDim: Record "Document Dimension"; ToTableID: Integer; ToNo: Code[20]; ToType: Integer; ToLineNo: Integer)
    var
        DocDim: Record "Document Dimension";
    begin
        WITH FromDocDim DO
            IF FINDSET THEN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := ToTableID;
                    DocDim."Document Type" := ToType;
                    DocDim."Document No." := ToNo;
                    DocDim."Line No." := ToLineNo;
                    DocDim."Dimension Code" := "Dimension Code";
                    DocDim."Dimension Value Code" := "Dimension Value Code";
                    DocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveDocDimArchvToDocDim(var DocDimArchv: Record "5106"; ToTableID: Integer; ToNo: Code[20]; ToType: Integer; ToLineNo: Integer)
    var
        DocDim: Record "Document Dimension";
    begin
        WITH DocDimArchv DO
            IF FINDSET THEN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := ToTableID;
                    DocDim."Document Type" := ToType;
                    DocDim."Document No." := ToNo;
                    DocDim."Line No." := ToLineNo;
                    DocDim."Dimension Code" := "Dimension Code";
                    DocDim."Dimension Value Code" := "Dimension Value Code";
                    DocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveLedgEntryDimToDocDim(var LedgEntryDim: Record "355"; ToTableID: Integer; ToNo: Code[20]; ToLineNo: Integer; ToType: Integer)
    var
        DocDim: Record "Document Dimension";
    begin
        WITH LedgEntryDim DO
            IF FINDSET THEN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := ToTableID;
                    DocDim."Document Type" := ToType;
                    DocDim."Document No." := ToNo;
                    DocDim."Line No." := ToLineNo;
                    DocDim."Dimension Code" := "Dimension Code";
                    DocDim."Dimension Value Code" := "Dimension Value Code";
                    DocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveProdDocDimToProdDocDim(var FromProdDocDim: Record "358"; ToTableID: Integer; ToStatus: Option; ToNo: Code[20])
    var
        ProdDocDim: Record "358";
    begin
        WITH FromProdDocDim DO
            IF FINDSET THEN
                REPEAT
                    ProdDocDim.INIT;
                    ProdDocDim."Table ID" := ToTableID;
                    ProdDocDim."Document Status" := ToStatus;
                    ProdDocDim."Document No." := ToNo;
                    ProdDocDim."Document Line No." := "Document Line No.";
                    ProdDocDim."Line No." := "Line No.";
                    ProdDocDim."Dimension Code" := "Dimension Code";
                    ProdDocDim."Dimension Value Code" := "Dimension Value Code";
                    ProdDocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveJnlLineDimToProdDocDim(var JnlLineDim: Record "Gen. Journal Line Dimension"; ToTableID: Integer; ToStatus: Option; ToNo: Code[20]; ToDocLineNo: Integer; ToLineNo: Integer)
    var
        ProdDocDim: Record "358";
    begin
        WITH JnlLineDim DO
            IF FINDSET THEN
                REPEAT
                    ProdDocDim.INIT;
                    ProdDocDim."Table ID" := ToTableID;
                    ProdDocDim."Document Status" := ToStatus;
                    ProdDocDim."Document No." := ToNo;
                    ProdDocDim."Document Line No." := ToDocLineNo;
                    ProdDocDim."Line No." := ToLineNo;
                    ProdDocDim."Dimension Code" := "Dimension Code";
                    ProdDocDim."Dimension Value Code" := "Dimension Value Code";
                    ProdDocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveJnlLineDimToDocDim(var JnlLineDim: Record "Gen. Journal Line Dimension"; ToTableID: Integer; ToType: Integer; ToNo: Code[20]; ToLineNo: Integer)
    var
        DocDim: Record "Document Dimension";
    begin
        WITH JnlLineDim DO
            IF FINDSET THEN
                REPEAT
                    DocDim.INIT;
                    DocDim."Table ID" := ToTableID;
                    DocDim."Document Type" := ToType;
                    DocDim."Document No." := ToNo;
                    DocDim."Line No." := ToLineNo;
                    DocDim."Dimension Code" := "Dimension Code";
                    DocDim."Dimension Value Code" := "Dimension Value Code";
                    DocDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure MoveJnlLineDimToJnlLineDim(var JnlLineDim: Record "Gen. Journal Line Dimension"; ToTableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer)
    var
        ToJnlLineDim: Record "Gen. Journal Line Dimension";
    begin
        WITH JnlLineDim DO
            IF FINDSET THEN
                REPEAT
                    ToJnlLineDim.INIT;
                    ToJnlLineDim."Table ID" := ToTableID;
                    ToJnlLineDim."Journal Template Name" := JnlTemplateName;
                    ToJnlLineDim."Journal Batch Name" := JnlBatchName;
                    ToJnlLineDim."Journal Line No." := JnlLineNo;
                    ToJnlLineDim."Dimension Code" := "Dimension Code";
                    ToJnlLineDim."Dimension Value Code" := "Dimension Value Code";
                    ToJnlLineDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CopyLedgEntryDimToLedgEntryDim(FromTableID: Integer; FromEntryNo: Integer; ToTableID: Integer; ToEntryNo: Integer)
    var
        FromLedgEntryDim: Record "355";
        ToLedgEntryDim: Record "355";
    begin
        WITH FromLedgEntryDim DO BEGIN
            SETRANGE("Table ID", FromTableID);
            SETRANGE("Entry No.", FromEntryNo);
            IF FINDSET THEN BEGIN
                REPEAT
                    ToLedgEntryDim := FromLedgEntryDim;
                    ToLedgEntryDim."Table ID" := ToTableID;
                    ToLedgEntryDim."Entry No." := ToEntryNo;
                    ToLedgEntryDim.INSERT;
                UNTIL NEXT = 0;
            END;
        END;
    end;

    procedure MoveTempFromDimToTempToDim(var TempFromLineDim: Record "Document Dimension" temporary; var TempToLineDim: Record "Document Dimension" temporary)
    begin
        IF TempFromLineDim.FINDSET THEN
            REPEAT
                TempToLineDim.INIT;
                TempToLineDim := TempFromLineDim;
                TempToLineDim.INSERT;
            UNTIL TempFromLineDim.NEXT = 0;
        TempFromLineDim.DELETEALL;
    end;

    procedure TransferTempToDimToDocDim(var TempToLineDim: Record "Document Dimension" temporary)
    var
        ToDocDim: Record "Document Dimension";
    begin
        IF TempToLineDim.FINDSET THEN
            REPEAT
                ToDocDim := TempToLineDim;
                ToDocDim.INSERT;
            UNTIL TempToLineDim.NEXT = 0;
        TempToLineDim.DELETEALL;
    end;

    procedure LookupDimValueCodeNoUpdate(FieldNumber: Integer)
    var
        DimVal: Record "349";
        GLSetup: Record "General Ledger Setup";
    begin
        GetGLSetup;
        IF GLSetupShortcutDimCode[FieldNumber] = '' THEN
            ERROR(Text002, GLSetup.TABLECAPTION);
        DimVal.SETRANGE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
        IF FORM.RUNMODAL(0, DimVal) = ACTION::LookupOK THEN;
    end;

    procedure GlobalDimNo(DimensionCode: Code[20]): Integer
    var
        Index: Integer;
    begin
        GetGLSetup;

        FOR Index := 1 TO ARRAYLEN(GLSetupShortcutDimCode) DO
            IF GLSetupShortcutDimCode[Index] = DimensionCode THEN
                EXIT(Index);

        EXIT(0);
    end;

    procedure MoveJnlLineDimToBuf(var JnlLineDim: Record "Gen. Journal Line Dimension")
    begin
        IF JnlLineDim.FINDSET THEN BEGIN
            TempDimBuf1.RESET;
            TempDimBuf1.DELETEALL;
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := JnlLineDim."Table ID";
                TempDimBuf1."Dimension Code" := JnlLineDim."Dimension Code";
                TempDimBuf1."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                TempDimBuf1.INSERT;
            UNTIL JnlLineDim.NEXT = 0;
            JnlLineDim.DELETEALL;
        END;
    end;

    procedure CopyJnlLineDimToICJnlDim(TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option Rejected,Created; LineNo: Integer; var TempJnlLineDim: Record "Gen. Journal Line Dimension" temporary)
    var
        InOutBoxJnlLineDim: Record "423";
        ICDim: Code[20];
        ICDimValue: Code[20];
    begin
        IF TempJnlLineDim.FINDSET THEN
            REPEAT
                ICDim := ConvertDimtoICDim(TempJnlLineDim."Dimension Code");
                ICDimValue := ConvertDimValuetoICDimVal(TempJnlLineDim."Dimension Code", TempJnlLineDim."Dimension Value Code");
                IF (ICDim <> '') AND (ICDimValue <> '') THEN BEGIN
                    InOutBoxJnlLineDim."Table ID" := TableID;
                    InOutBoxJnlLineDim."IC Partner Code" := PartnerCode;
                    InOutBoxJnlLineDim."Transaction No." := TransactionNo;
                    InOutBoxJnlLineDim."Transaction Source" := TransactionSource;
                    InOutBoxJnlLineDim."Line No." := LineNo;
                    InOutBoxJnlLineDim."Dimension Code" := ICDim;
                    InOutBoxJnlLineDim."Dimension Value Code" := ICDimValue;
                    InOutBoxJnlLineDim.INSERT;
                END;
            UNTIL TempJnlLineDim.NEXT = 0;
    end;

    procedure CopyICJnlDimToJnlLineDim(TableID: Integer; var TempICInOutBoxJnlLineDim: Record "423" temporary; GenJnlLine: Record "81")
    var
        JournalLineDim: Record "Gen. Journal Line Dimension";
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.GET;
        IF TempICInOutBoxJnlLineDim.FINDSET THEN
            REPEAT
                JournalLineDim."Table ID" := TableID;
                JournalLineDim."Journal Template Name" := GenJnlLine."Journal Template Name";
                JournalLineDim."Journal Batch Name" := GenJnlLine."Journal Batch Name";
                JournalLineDim."Journal Line No." := GenJnlLine."Line No.";
                JournalLineDim."Dimension Code" := ConvertICDimtoDim(TempICInOutBoxJnlLineDim."Dimension Code");
                JournalLineDim."Dimension Value Code" := ConvertICDimValuetoDimValue(
                  TempICInOutBoxJnlLineDim."Dimension Code", TempICInOutBoxJnlLineDim."Dimension Value Code");
                IF (JournalLineDim."Dimension Code" <> '') AND (JournalLineDim."Dimension Value Code" <> '') THEN
                    IF NOT JournalLineDim.INSERT THEN
                        JournalLineDim.MODIFY;
                IF GLSetup."Shortcut Dimension 1 Code" = JournalLineDim."Dimension Code" THEN BEGIN
                    GenJnlLine."Shortcut Dimension 1 Code" := JournalLineDim."Dimension Value Code";
                    GenJnlLine.MODIFY;
                END
                ELSE
                    IF GLSetup."Shortcut Dimension 2 Code" = JournalLineDim."Dimension Code" THEN BEGIN
                        GenJnlLine."Shortcut Dimension 2 Code" := JournalLineDim."Dimension Value Code";
                        GenJnlLine.MODIFY;
                    END;
            UNTIL TempICInOutBoxJnlLineDim.NEXT = 0;
    end;

    procedure CopyICJnlDimToICJnlDim(var FromInOutBoxLineDim: Record "423"; var ToInOutBoxlineDim: Record "423")
    begin
        IF FromInOutBoxLineDim.FINDSET THEN
            REPEAT
                ToInOutBoxlineDim := FromInOutBoxLineDim;
                ToInOutBoxlineDim.INSERT;
            UNTIL FromInOutBoxLineDim.NEXT = 0;
    end;

    procedure CopyDocDimtoICDocDim(TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Option Rejected,Created; LineNo: Integer; var TempDocDim: Record "Document Dimension" temporary)
    var
        InOutBoxDocDim: Record "442";
        ICDim: Code[20];
        ICDimValue: Code[20];
    begin
        IF TempDocDim.FINDSET THEN
            REPEAT
                ICDim := ConvertDimtoICDim(TempDocDim."Dimension Code");
                ICDimValue := ConvertDimValuetoICDimVal(TempDocDim."Dimension Code", TempDocDim."Dimension Value Code");
                IF (ICDim <> '') AND (ICDimValue <> '') THEN BEGIN
                    InOutBoxDocDim."Table ID" := TableID;
                    InOutBoxDocDim."IC Partner Code" := PartnerCode;
                    InOutBoxDocDim."Transaction No." := TransactionNo;
                    InOutBoxDocDim."Transaction Source" := TransactionSource;
                    InOutBoxDocDim."Line No." := LineNo;
                    InOutBoxDocDim."Dimension Code" := ICDim;
                    InOutBoxDocDim."Dimension Value Code" := ICDimValue;
                    InOutBoxDocDim.INSERT;
                END;
            UNTIL TempDocDim.NEXT = 0;
    end;

    procedure CopyICDocDimtoICDocDim(FromSourceICDocDim: Record "442"; var ToSourceICDocDim: Record "442"; ToTableID: Integer; ToTransactionSource: Integer)
    begin
        WITH FromSourceICDocDim DO BEGIN
            SetICDocDimFilters(FromSourceICDocDim, "Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
            IF FromSourceICDocDim.FINDSET THEN
                REPEAT
                    ToSourceICDocDim := FromSourceICDocDim;
                    ToSourceICDocDim."Table ID" := ToTableID;
                    ToSourceICDocDim."Transaction Source" := ToTransactionSource;
                    ToSourceICDocDim.INSERT;
                UNTIL FromSourceICDocDim.NEXT = 0;
        END;
    end;

    procedure MoveICDocDimtoICDocDim(FromSourceICDocDim: Record "442"; var ToSourceICDocDim: Record "442"; ToTableID: Integer; ToTransactionSource: Integer)
    begin
        WITH FromSourceICDocDim DO BEGIN
            SetICDocDimFilters(FromSourceICDocDim, "Table ID", "Transaction No.", "IC Partner Code", "Transaction Source", "Line No.");
            IF FromSourceICDocDim.FINDSET THEN
                REPEAT
                    ToSourceICDocDim := FromSourceICDocDim;
                    ToSourceICDocDim."Table ID" := ToTableID;
                    ToSourceICDocDim."Transaction Source" := ToTransactionSource;
                    ToSourceICDocDim.INSERT;
                    FromSourceICDocDim.DELETE;
                UNTIL FromSourceICDocDim.NEXT = 0;
        END;
    end;

    procedure SetICDocDimFilters(var ICDocDim: Record "442"; TableID: Integer; TransactionNo: Integer; PartnerCode: Code[20]; TransactionSource: Integer; LineNo: Integer)
    begin
        ICDocDim.RESET;
        ICDocDim.SETRANGE("Table ID", TableID);
        ICDocDim.SETRANGE("Transaction No.", TransactionNo);
        ICDocDim.SETRANGE("IC Partner Code", PartnerCode);
        ICDocDim.SETRANGE("Transaction Source", TransactionSource);
        ICDocDim.SETRANGE("Line No.", LineNo);
    end;

    procedure DeleteICDocDim("Table ID": Integer; "IC Transaction No.": Integer; "IC Partner Code": Code[20]; "Transaction Source": Option Rejected,Created; LineNo: Integer)
    var
        ICDocDim: Record "442";
    begin
        SetICDocDimFilters(ICDocDim, "Table ID", "IC Transaction No.", "IC Partner Code", "Transaction Source", LineNo);
        IF NOT ICDocDim.ISEMPTY THEN
            ICDocDim.DELETEALL;
    end;

    procedure DeleteICJnlDim("Table ID": Integer; "IC Transaction No.": Integer; "IC Partner Code": Code[20]; "Transaction Source": Option Rejected,Created; LineNo: Integer)
    var
        ICJnlDim: Record "423";
    begin
        ICJnlDim.SETRANGE("Table ID", "Table ID");
        ICJnlDim.SETRANGE("Transaction No.", "IC Transaction No.");
        ICJnlDim.SETRANGE("IC Partner Code", "IC Partner Code");
        ICJnlDim.SETRANGE("Transaction Source", "Transaction Source");
        ICJnlDim.SETRANGE("Line No.", LineNo);
        IF NOT ICJnlDim.ISEMPTY THEN
            ICJnlDim.DELETEALL;
    end;

    procedure ConvertICDimtoDim(FromICDim: Code[20]) DimCode: Code[20]
    var
        ICDim: Record "411";
    begin
        IF ICDim.GET(FromICDim) THEN
            DimCode := ICDim."Map-to Dimension Code";
    end;

    procedure ConvertICDimValuetoDimValue(FromICDim: Code[20]; FromICDimValue: Code[20]) DimValueCode: Code[20]
    var
        ICDimValue: Record "412";
    begin
        IF ICDimValue.GET(FromICDim, FromICDimValue) THEN
            DimValueCode := ICDimValue."Map-to Dimension Value Code";
    end;

    procedure ConvertDimtoICDim(FromDim: Code[20]) ICDimCode: Code[20]
    var
        Dim: Record "348";
    begin
        IF Dim.GET(FromDim) THEN
            ICDimCode := Dim."Map-to IC Dimension Code";
    end;

    procedure ConvertDimValuetoICDimVal(FromDim: Code[20]; FromDimValue: Code[20]) ICDimValueCode: Code[20]
    var
        DimValue: Record "349";
    begin
        IF DimValue.GET(FromDim, FromDimValue) THEN
            ICDimValueCode := DimValue."Map-to IC Dimension Value Code";
    end;

    procedure TestDimValue(var JnlLineDim: Record "Gen. Journal Line Dimension"): Boolean
    var
        i: Integer;
    begin
        TempDimBuf1.RESET;
        TempDimBuf1.DELETEALL;
        IF JnlLineDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := DATABASE::"Journal Line Dimension";
                TempDimBuf1."Dimension Code" := JnlLineDim."Dimension Code";
                IF JnlLineDim."Dimension Value Code" <> '' THEN BEGIN
                    TempDimBuf1."Entry No." := i;
                    TempDimBuf1."Dimension Value Code" := JnlLineDim."Dimension Value Code";
                    TempDimBuf1.INSERT;
                    i := i + 1;
                END;
                IF JnlLineDim."New Dimension Value Code" <> '' THEN
                    CheckNewDimValue := TRUE;
            UNTIL JnlLineDim.NEXT = 0;
        END;
        EXIT(CheckDimComb);
    end;

    procedure TestNewDimValue(var JnlLineDim: Record "Gen. Journal Line Dimension"): Boolean
    var
        i: Integer;
    begin
        TempDimBuf1.RESET;
        TempDimBuf1.DELETEALL;
        IF JnlLineDim.FINDSET THEN BEGIN
            i := 1;
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := DATABASE::"Journal Line Dimension";
                TempDimBuf1."Dimension Code" := JnlLineDim."Dimension Code";
                IF JnlLineDim."New Dimension Value Code" <> '' THEN BEGIN
                    TempDimBuf1."Entry No." := i;
                    TempDimBuf1."Dimension Value Code" := JnlLineDim."New Dimension Value Code";
                    TempDimBuf1.INSERT;
                    i := i + 1;
                END;
            UNTIL JnlLineDim.NEXT = 0;
        END;
        EXIT(CheckDimComb);
    end;

    procedure MoveDimBufToItemBudgetDim(var FromDimBuf: Record "Dimension Buffer"; ToEntryNo: Integer)
    var
        ItemBudgetDim: Record "7135";
    begin
        WITH FromDimBuf DO
            IF FINDSET THEN
                REPEAT
                    ItemBudgetDim."Entry No." := ToEntryNo;
                    ItemBudgetDim."Dimension Code" := "Dimension Code";
                    ItemBudgetDim."Dimension Value Code" := "Dimension Value Code";
                    ItemBudgetDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure CheckICDimValue(ICDimCode: Code[20]; ICDimValCode: Code[20]): Boolean
    var
        ICDimVal: Record "412";
    begin
        IF (ICDimCode <> '') AND (ICDimValCode <> '') THEN BEGIN
            IF ICDimVal.GET(ICDimCode, ICDimValCode) THEN BEGIN
                IF ICDimVal.Blocked THEN BEGIN
                    DimErr :=
                      STRSUBSTNO(
                        Text016, ICDimVal.TABLECAPTION, ICDimCode, ICDimValCode);
                    EXIT(FALSE);
                END;
                IF NOT (ICDimVal."Dimension Value Type" IN
                  [ICDimVal."Dimension Value Type"::Standard,
                   ICDimVal."Dimension Value Type"::"Begin-Total"])
                THEN BEGIN
                    DimErr :=
                      STRSUBSTNO(Text017, ICDimVal.FIELDCAPTION("Dimension Value Type"),
                      ICDimVal.TABLECAPTION, ICDimCode, ICDimValCode, FORMAT(ICDimVal."Dimension Value Type"));
                    EXIT(FALSE);
                END;
            END ELSE BEGIN
                DimErr :=
                  STRSUBSTNO(
                    Text018, ICDimVal.TABLECAPTION, ICDimCode);
                EXIT(FALSE);
            END;
        END;
        EXIT(TRUE);
    end;

    procedure CheckICDim(ICDimCode: Code[20]): Boolean
    var
        ICDim: Record "411";
    begin
        IF ICDim.GET(ICDimCode) THEN BEGIN
            IF ICDim.Blocked THEN BEGIN
                DimErr :=
                  STRSUBSTNO(Text014, ICDim.TABLECAPTION, ICDimCode);
                EXIT(FALSE);
            END;
        END ELSE BEGIN
            DimErr :=
              STRSUBSTNO(Text015, ICDim.TABLECAPTION, ICDimCode);
            EXIT(FALSE);
        END;
        EXIT(TRUE);
    end;

    procedure GetServContractDim(TableID: Integer; DocType: Option; DocNo: Code[20]; DocLineNo: Integer; "Source Code": Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        ServContrDim: Record "389";
    begin
        GetGLSetup;
        IF TempDimBuf1.FIND('-') THEN BEGIN
            REPEAT
                TempDimBuf2.INIT;
                TempDimBuf2 := TempDimBuf1;
                TempDimBuf2.INSERT;
            UNTIL TempDimBuf1.NEXT = 0;
        END;
        IF (TableID <> 0) AND (DocNo <> '') THEN BEGIN
            ServContrDim.SETRANGE("Table ID", TableID);
            ServContrDim.SETRANGE(Type, DocType);
            ServContrDim.SETRANGE("No.", DocNo);
            ServContrDim.SETRANGE("Line No.", DocLineNo);
            IF ServContrDim.FIND('-') THEN BEGIN
                REPEAT
                    IF ServContrDim."Dimension Value Code" <> '' THEN BEGIN
                        TempDimBuf2.SETRANGE("Dimension Code", ServContrDim."Dimension Code");
                        IF NOT TempDimBuf2.FIND('-') THEN BEGIN
                            TempDimBuf2.INIT;
                            TempDimBuf2."Table ID" := ServContrDim."Table ID";
                            TempDimBuf2."Entry No." := 0;
                            TempDimBuf2."Dimension Code" := ServContrDim."Dimension Code";
                            TempDimBuf2."Dimension Value Code" := ServContrDim."Dimension Value Code";
                            TempDimBuf2.INSERT;
                        END;
                        IF GLSetupShortcutDimCode[1] = TempDimBuf2."Dimension Code" THEN
                            GlobalDim1Code := TempDimBuf2."Dimension Value Code";
                        IF GLSetupShortcutDimCode[2] = TempDimBuf2."Dimension Code" THEN
                            GlobalDim2Code := TempDimBuf2."Dimension Value Code";
                    END;
                UNTIL ServContrDim.NEXT = 0;
            END;
        END;
        TempDimBuf2.RESET;
    end;

    procedure MoveTempDimToBuf()
    begin
        IF TempDimBuf2.FINDSET THEN BEGIN
            TempDimBuf1.RESET;
            TempDimBuf1.DELETEALL;
            REPEAT
                TempDimBuf1.INIT;
                TempDimBuf1."Table ID" := TempDimBuf2."Table ID";
                TempDimBuf1."Dimension Code" := TempDimBuf2."Dimension Code";
                TempDimBuf1."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                TempDimBuf1.INSERT;
            UNTIL TempDimBuf2.NEXT = 0;
            TempDimBuf2.DELETEALL;
        END;
    end;

    procedure SaveJobTaskDim("Job No.": Code[20]; "Job Task No.": Code[20]; FieldNumber: Integer; ShortcutDimCode: Code[20])
    var
        JobTaskDim: Record "1002";
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ChangeLogMgt: Codeunit "423";
    begin
        GetGLSetup;
        IF ShortcutDimCode <> '' THEN BEGIN
            IF JobTaskDim.GET("Job No.", "Job Task No.", GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                xRecRef.GETTABLE(JobTaskDim);
                JobTaskDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                JobTaskDim.MODIFY;
                RecRef.GETTABLE(JobTaskDim);
                ChangeLogMgt.LogModification(RecRef, xRecRef);
            END ELSE BEGIN
                JobTaskDim.INIT;
                JobTaskDim.VALIDATE("Job No.", "Job No.");
                JobTaskDim.VALIDATE("Job Task No.", "Job Task No.");
                JobTaskDim.VALIDATE("Dimension Code", GLSetupShortcutDimCode[FieldNumber]);
                JobTaskDim.VALIDATE("Dimension Value Code", ShortcutDimCode);
                JobTaskDim.INSERT;
                RecRef.GETTABLE(JobTaskDim);
                ChangeLogMgt.LogInsertion(RecRef);
            END;
        END ELSE
            IF JobTaskDim.GET("Job No.", "Job Task No.", GLSetupShortcutDimCode[FieldNumber]) THEN BEGIN
                RecRef.GETTABLE(JobTaskDim);
                JobTaskDim.DELETE;
                ChangeLogMgt.LogDeletion(RecRef)
            END;
    end;

    procedure SaveJobTaskTempDim(FieldNumber: Integer; ShortcutDimCode: Code[20])
    begin
        GetGLSetup;
        IF ShortcutDimCode <> '' THEN BEGIN
            IF JobTaskDimTemp.GET('', '', GLSetupShortcutDimCode[FieldNumber])
            THEN BEGIN
                JobTaskDimTemp."Dimension Value Code" := ShortcutDimCode;
                JobTaskDimTemp.MODIFY;
            END ELSE BEGIN
                JobTaskDimTemp.INIT;
                JobTaskDimTemp."Dimension Code" := GLSetupShortcutDimCode[FieldNumber];
                JobTaskDimTemp."Dimension Value Code" := ShortcutDimCode;
                JobTaskDimTemp.INSERT;
            END;
        END ELSE
            IF JobTaskDimTemp.GET('', '', GLSetupShortcutDimCode[FieldNumber]) THEN
                JobTaskDimTemp.DELETE;
    end;

    procedure InsertJobTaskDim("Job No.": Code[20]; "Job Task No.": Code[20]; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        DefaultDim: Record "352";
        JobTaskDim: Record "1002";
    begin
        GetGLSetup;
        DefaultDim.SETRANGE("Table ID", DATABASE::Job);
        DefaultDim.SETRANGE("No.", "Job No.");
        IF DefaultDim.FINDSET(FALSE, FALSE) THEN
            REPEAT
                IF DefaultDim."Dimension Value Code" <> '' THEN BEGIN
                    JobTaskDim.INIT;
                    JobTaskDim."Job No." := "Job No.";
                    JobTaskDim."Job Task No." := "Job Task No.";
                    JobTaskDim."Dimension Code" := DefaultDim."Dimension Code";
                    JobTaskDim."Dimension Value Code" := DefaultDim."Dimension Value Code";
                    JobTaskDim.INSERT;
                    IF JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                        GlobalDim1Code := JobTaskDim."Dimension Value Code";
                    IF JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                        GlobalDim2Code := JobTaskDim."Dimension Value Code";
                END;
            UNTIL DefaultDim.NEXT = 0;

        JobTaskDimTemp.RESET;
        IF JobTaskDimTemp.FINDSET THEN
            REPEAT
                IF NOT JobTaskDim.GET("Job No.", "Job Task No.", JobTaskDimTemp."Dimension Code") THEN BEGIN
                    JobTaskDim.INIT;
                    JobTaskDim."Job No." := "Job No.";
                    JobTaskDim."Job Task No." := "Job Task No.";
                    JobTaskDim."Dimension Code" := JobTaskDimTemp."Dimension Code";
                    JobTaskDim."Dimension Value Code" := JobTaskDimTemp."Dimension Value Code";
                    JobTaskDim.INSERT;
                    IF JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                        GlobalDim1Code := JobTaskDim."Dimension Value Code";
                    IF JobTaskDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                        GlobalDim2Code := JobTaskDim."Dimension Value Code";
                END;
            UNTIL JobTaskDimTemp.NEXT = 0;
        JobTaskDimTemp.DELETEALL;
    end;

    procedure DeleteJobTaskTempDim()
    var
        JobTaskDim: Record "1002";
    begin
        JobTaskDimTemp.RESET;
        JobTaskDimTemp.DELETEALL;
    end;

    procedure UpdateSCInvLineDim(var ServContractDim: Record "389"; var DocDim: Record "Document Dimension"; ServLine: Record "5902"; ServContractHeader: Record "5965"; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    begin
        GetGLSetup;
        IF ServContractDim.FIND('-') THEN BEGIN
            REPEAT
                DocDim.SETRANGE("Dimension Code", ServContractDim."Dimension Code");
                IF DocDim.FIND('-') THEN BEGIN
                    DocDim."Dimension Value Code" := ServContractDim."Dimension Value Code";
                    DocDim.MODIFY;
                END ELSE BEGIN
                    DocDim.INIT;
                    DocDim."Table ID" := DATABASE::"Service Line";
                    DocDim."Document Type" := ServLine."Document Type";
                    DocDim."Document No." := ServLine."Document No.";
                    DocDim."Line No." := ServLine."Line No.";
                    DocDim."Dimension Code" := ServContractDim."Dimension Code";
                    DocDim."Dimension Value Code" := ServContractDim."Dimension Value Code";
                    DocDim.INSERT;
                END;
                IF DocDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                    GlobalDim1Code := DocDim."Dimension Value Code";
                IF DocDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                    GlobalDim2Code := DocDim."Dimension Value Code";
            UNTIL ServContractDim.NEXT = 0;
        END;
    end;

    procedure CopyJnlLineDimToBuffer(TableID: Integer; JnlTemplateName: Code[10]; JnlBatchName: Code[10]; JnlLineNo: Integer; AllocationLineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    var
        FromJnlLineDim: Record "Gen. Journal Line Dimension";
    begin
        GetGLSetup;
        WITH FromJnlLineDim DO BEGIN
            SETRANGE("Table ID", TableID);
            SETRANGE("Journal Template Name", JnlTemplateName);
            SETRANGE("Journal Batch Name", JnlBatchName);
            SETRANGE("Journal Line No.", JnlLineNo);
            SETRANGE("Allocation Line No.", 0);
            TempDimBuf1.RESET;
            TempDimBuf1.DELETEALL;
            IF FINDSET THEN
                REPEAT
                    TempDimBuf1.INIT;
                    TempDimBuf1."Table ID" := 0;
                    TempDimBuf1."Entry No." := 0;
                    TempDimBuf1."Dimension Code" := "Dimension Code";
                    TempDimBuf1."Dimension Value Code" := "Dimension Value Code";
                    TempDimBuf1.INSERT;
                    IF GLSetupShortcutDimCode[1] = TempDimBuf1."Dimension Code" THEN
                        GlobalDim1Code := TempDimBuf1."Dimension Value Code";
                    IF GLSetupShortcutDimCode[2] = TempDimBuf1."Dimension Code" THEN
                        GlobalDim2Code := TempDimBuf1."Dimension Value Code";
                UNTIL NEXT = 0;
        END;
    end;

    procedure UpdateDocDefaultDim2(var DocDim: Record "Document Dimension"; TableID: Integer; DocType: Option; DocNo: Code[20]; LineNo: Integer; var GlobalDim1Code: Code[20]; var GlobalDim2Code: Code[20])
    begin
        GetGLSetup;
        DocDim.SETRANGE("Table ID", TableID);
        DocDim.SETRANGE("Document Type", DocType);
        DocDim.SETRANGE("Document No.", DocNo);
        DocDim.SETRANGE("Line No.", LineNo);
        DocDim.DELETEALL;
        GlobalDim1Code := '';
        GlobalDim2Code := '';
        IF TempDimBuf2.FIND('-') THEN BEGIN
            REPEAT
                DocDim.INIT;
                DocDim.VALIDATE("Table ID", TableID);
                DocDim.VALIDATE("Document Type", DocType);
                DocDim.VALIDATE("Document No.", DocNo);
                DocDim.VALIDATE("Line No.", LineNo);
                DocDim."Dimension Code" := TempDimBuf2."Dimension Code";
                DocDim."Dimension Value Code" := TempDimBuf2."Dimension Value Code";
                DocDim.INSERT;
                IF DocDim."Dimension Code" = GLSetupShortcutDimCode[1] THEN
                    GlobalDim1Code := DocDim."Dimension Value Code";
                IF DocDim."Dimension Code" = GLSetupShortcutDimCode[2] THEN
                    GlobalDim2Code := DocDim."Dimension Value Code";
            UNTIL TempDimBuf2.NEXT = 0;
            TempDimBuf2.RESET;
            TempDimBuf2.DELETEALL;
        END;
    end;

    procedure UpdateFromBufToTmpJnlLineDim(var ToJnlLineDim: Record "Gen. Journal Line Dimension"; ToTableId: Integer)
    begin
        //LS
        WITH TempDimBuf2 DO
            IF FIND('-') THEN
                REPEAT
                    ToJnlLineDim."Table ID" := ToTableId;
                    ToJnlLineDim."Dimension Code" := "Dimension Code";
                    ToJnlLineDim."Dimension Value Code" := "Dimension Value Code";
                    ToJnlLineDim.INSERT;
                UNTIL NEXT = 0;
    end;

    procedure GetShortcutDimCode(FieldNumber: Integer): Code[20]
    begin
        //LS
        GetGLSetup;
        EXIT(GLSetupShortcutDimCode[FieldNumber]);
    end;

    procedure ShowPostedDocDim(TableID: Integer; DocNo: Code[20]; LineNo: Integer; var ShortcutDimCode: array[8] of Code[20])
    var
        DocDim: Record "359";
        i: Integer;
    begin
        //APNT-HR1.0
        GetGLSetup;
        FOR i := 3 TO 8 DO BEGIN
            ShortcutDimCode[i] := '';
            IF GLSetupShortcutDimCode[i] <> '' THEN
                IF DocDim.GET(TableID, DocNo, LineNo, GLSetupShortcutDimCode[i]) THEN
                    ShortcutDimCode[i] := DocDim."Dimension Value Code";
        END;
        //APNT-HR1.0
    end;
}


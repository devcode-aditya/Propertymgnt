table 357 "Document Dimension"
{
    // CODE          DATE        NAME         DESCRIPTION
    // APNT-FIN1.0   28.11.11    Tanweer      Added code for Treasury Customization
    // DP = changes made by DVS
    // APNT-HR1.0    12.11.13    Sangeeta     Added code for HR & Payroll Customization.

    Caption = 'Document Dimension';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
            NotBlank = true;
            TableRelation = AllObj."Object ID" WHERE(Object Type=CONST(Table));
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order, ';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"," ";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Line No."; Integer)
        {
            Caption = 'Line No.';
        }
        field(5; "Dimension Code"; Code[20])
        {
            Caption = 'Dimension Code';
            NotBlank = true;
            TableRelation = Dimension;

            trigger OnValidate()
            begin
                IF NOT DimMgt.CheckDim("Dimension Code") THEN
                    ERROR(DimMgt.GetDimErr);
            end;
        }
        field(6; "Dimension Value Code"; Code[20])
        {
            Caption = 'Dimension Value Code';
            NotBlank = true;
            TableRelation = "Dimension Value".Code WHERE(Dimension Code=FIELD(Dimension Code));

            trigger OnValidate()
            begin
                IF NOT DimMgt.CheckDimValue("Dimension Code","Dimension Value Code") THEN
                  ERROR(DimMgt.GetDimErr);
            end;
        }
    }

    keys
    {
        key(Key1;"Table ID","Document Type","Document No.","Line No.","Dimension Code")
        {
            Clustered = true;
        }
        key(Key2;"Dimension Code","Dimension Value Code")
        {
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        GLSetup.GET;
        UpdateLineDim(Rec,TRUE);
        IF "Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
          UpdateGlobalDimCode(
            1,"Table ID","Document Type","Document No.","Line No.",'');
        IF "Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
          UpdateGlobalDimCode(
            2,"Table ID","Document Type","Document No.","Line No.",'');
    end;

    trigger OnInsert()
    begin
        TESTFIELD("Dimension Value Code");
        GLSetup.GET;
        UpdateLineDim(Rec,FALSE);
        IF "Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
          UpdateGlobalDimCode(
            1,"Table ID","Document Type","Document No.","Line No.","Dimension Value Code");
        IF "Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
          UpdateGlobalDimCode(
            2,"Table ID","Document Type","Document No.","Line No.","Dimension Value Code");
    end;

    trigger OnModify()
    begin
        GLSetup.GET;
        UpdateLineDim(Rec,FALSE);
        IF "Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
          UpdateGlobalDimCode(
            1,"Table ID","Document Type","Document No.","Line No.","Dimension Value Code");
        IF "Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
          UpdateGlobalDimCode(
            2,"Table ID","Document Type","Document No.","Line No.","Dimension Value Code");
    end;

    trigger OnRename()
    begin
        ERROR(Text000,TABLECAPTION);
    end;

    var
        Text000: Label 'You can not rename a %1.';
        Text001: Label 'You have changed a dimension.\\';
        Text002: Label 'Do you want to update the lines?';
        Text003: Label 'You may have changed a dimension.\\Do you want to update the lines?';
        GLSetup: Record "98";
        DimMgt: Codeunit "408";
        UpdateLine: Option NotSet,Update,DoNotUpdate;
        Text004: Label 'You have changed one or more dimensions on the %1, which is already shipped. When you post the line with the changed dimension to the general ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to keep the changed dimension?';
        Text005: Label 'Canceled.';
        Text006: Label 'You may have changed a dimension. Some lines are already shipped. When you post the line with the changed dimension to the general ledger, amounts on the Inventory Interim account will be out of balance when reported per dimension.\\Do you want to update the lines?';
        "DocNo.": Integer;
 
    procedure UpdateGlobalDimCode(GlobalDimCodeNo: Integer;"Table ID": Integer;"Document Type": Option;"Document No.": Code[20];"Line No.": Integer;NewDimValue: Code[20])
    var
        SalesHeader: Record "36";
        SalesLine: Record "37";
        PurchHeader: Record "38";
        PurchLine: Record "39";
        ReminderHeader: Record "295";
        FinChrgMemoHeader: Record "302";
        TransHeader: Record "5740";
        TransLine: Record "5741";
        ServHeader: Record "5900";
        ServLine: Record "5902";
        ServItemLine: Record "5901";
        StdSalesLine: Record "171";
        StdPurchLine: Record "174";
        StdServLine: Record "5997";
        LetterofCredit: Record "50012";
        TrustReceipt: Record "50015";
        Loan: Record "50018";
        Cheques: Record "50011";
        SalaryDisbHeader: Record "60043";
        SalaryDisbLines: Record "60044";
        EmpSalReview: Record "60027";
        EmpAbsnece: Record "5207";
        LoanAdvHeader: Record "60031";
    begin
        CASE "Table ID" OF
          DATABASE::"Sales Header":
            BEGIN
              IF SalesHeader.GET("Document Type","Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    SalesHeader."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    SalesHeader."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                SalesHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Sales Line":
            BEGIN
              IF SalesLine.GET("Document Type","Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    SalesLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    SalesLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                SalesLine.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Purchase Header":
            BEGIN
              IF PurchHeader.GET("Document Type","Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    PurchHeader."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    PurchHeader."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                PurchHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Purchase Line":
            BEGIN
              IF PurchLine.GET("Document Type","Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    PurchLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    PurchLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                PurchLine.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Reminder Header":
            BEGIN
              IF ReminderHeader.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    ReminderHeader."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    ReminderHeader."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                ReminderHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Finance Charge Memo Header":
            BEGIN
              IF FinChrgMemoHeader.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    FinChrgMemoHeader."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    FinChrgMemoHeader."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                FinChrgMemoHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Transfer Header":
            BEGIN
              IF TransHeader.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    TransHeader."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    TransHeader."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                TransHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Transfer Line":
            BEGIN
              IF TransLine.GET("Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    TransLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    TransLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                TransLine.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Service Header":
            BEGIN
              IF ServHeader.GET("Document Type","Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    ServHeader."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    ServHeader."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                ServHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Service Line":
            BEGIN
              IF ServLine.GET("Document Type","Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    ServLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    ServLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                ServLine.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Service Item Line":
            BEGIN
              IF ServItemLine.GET("Document Type","Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    ServItemLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    ServItemLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                ServItemLine.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Standard Sales Line":
            BEGIN
              IF StdSalesLine.GET("Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    StdSalesLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    StdSalesLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                StdSalesLine.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Standard Purchase Line":
            BEGIN
              IF StdPurchLine.GET("Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    StdPurchLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    StdPurchLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                StdPurchLine.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Standard Service Line":
            BEGIN
              IF StdServLine.GET("Document No.","Line No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    StdServLine."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    StdServLine."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                StdServLine.MODIFY(TRUE);
              END;
            END;
          //APNT-FIN1.0
          DATABASE::"Letter of Credit":
            BEGIN
              IF LetterofCredit.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    LetterofCredit."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    LetterofCredit."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                LetterofCredit.MODIFY(TRUE);
              END;
            END;
         /* DATABASE::"Shipping Guarantee":
            BEGIN
              IF ShippingGuarantee.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    ShippingGuarantee."Global Dimension 1 Code" := NewDimValue;
                  2:
                    ShippingGuarantee."Global Dimension 2 Code" := NewDimValue;
                END;
                ShippingGuarantee.MODIFY(TRUE);
              END;
            END;  */
          DATABASE::"Trust Receipt":
            BEGIN
              IF TrustReceipt.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    TrustReceipt."Global Dimension 1 Code" := NewDimValue;
                  2:
                    TrustReceipt."Global Dimension 2 Code" := NewDimValue;
                END;
                TrustReceipt.MODIFY(TRUE);
              END;
            END;
          DATABASE::Loan:
            BEGIN
              IF Loan.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    Loan."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    Loan."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                Loan.MODIFY(TRUE);
              END;
            END;
          DATABASE::Cheques:
            BEGIN
              EVALUATE("DocNo.","Document No.");
              IF Cheques.GET("DocNo.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    Cheques."Global Dimension 1 Code" := NewDimValue;
                  2:
                    Cheques."Global Dimension 2 Code" := NewDimValue;
                END;
                Cheques.MODIFY(TRUE);
              END;
            END;
         /* DATABASE::"Fixed Deposit":
            BEGIN
              IF FixedDeposit.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    FixedDeposit."Global Dimension 1 Code" := NewDimValue;
                  2:
                    FixedDeposit."Global Dimension 2 Code" := NewDimValue;
                END;
                FixedDeposit.MODIFY(TRUE);
              END;
            END; */
          //APNT-FIN1.0
          //APNT-HR1.0
          DATABASE::"Salary Disbursments Header":
            BEGIN
              IF SalaryDisbHeader.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    SalaryDisbHeader."Global Dimension 1 Code" := NewDimValue;
                  2:
                    SalaryDisbHeader."Global Dimension 2 Code" := NewDimValue;
                END;
                SalaryDisbHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Leave Registration":
            BEGIN
              IF EmpAbsnece.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    EmpAbsnece."Global Dimension 1 Code" := NewDimValue;
                  2:
                    EmpAbsnece."Global Dimension 2 Code" := NewDimValue;
                END;
                EmpAbsnece.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Loan & Advances Header":
            BEGIN
              IF LoanAdvHeader.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    LoanAdvHeader."Shortcut Dimension 1 Code" := NewDimValue;
                  2:
                    LoanAdvHeader."Shortcut Dimension 2 Code" := NewDimValue;
                END;
                LoanAdvHeader.MODIFY(TRUE);
              END;
            END;
          DATABASE::"Employee Salary Review":
            BEGIN
              IF EmpSalReview.GET("Document No.") THEN BEGIN
                CASE GlobalDimCodeNo OF
                  1:
                    EmpSalReview."Global Dimension 1 Code" := NewDimValue;
                  2:
                    EmpSalReview."Global Dimension 2 Code" := NewDimValue;
                END;
                EmpSalReview.MODIFY(TRUE);
              END;
            END;
          //APNT-HR1.0
        
        END;

    end;
 
    procedure UpdateLineDim(var DocDim: Record "357";FromOnDelete: Boolean)
    var
        NewDocDim: Record "357";
        SalesLine: Record "37";
        PurchaseLine: Record "39";
        TransLine: Record "5741";
        ServItemLine: Record "5901";
        ServLine: Record "5902";
        Question: Text[250];
        UpdateDim: Boolean;
        AgreementLine: Record "33016816";
        WorkOrderLine: Record "33016825";
        SalDisbLines: Record "60044";
        SalReviewLines: Record "60045";
        LoanAdvLines: Record "60032";
        EmAbsneceLines: Record "60030";
    begin
        WITH DocDim DO BEGIN
          IF ("Table ID" = DATABASE::"Sales Header") OR
             ("Table ID" = DATABASE::"Purchase Header") OR
             ("Table ID" = DATABASE::"Transfer Header") OR
             ("Table ID" = DATABASE::"Service Header") OR
             ("Table ID" = DATABASE::"Service Item Line")
             //DP6.01.01 START
             OR ("Table ID" = DATABASE::"Agreement Header")
             OR ("Table ID" = DATABASE::"Work Order Header")
             //DP6.01.01 STOP
             OR ("Table ID" = DATABASE::"Salary Disbursments Header") //APNT-HR1.0
             OR ("Table ID" = DATABASE::"Employee Salary Review") //APNT-HR1.0
             OR ("Table ID" = DATABASE::"Leave Registration") //APNT-HR1.0
             OR ("Table ID" = DATABASE::"Transfers/ Promotions") //APNT-HR1.0
             OR ("Table ID" = DATABASE::"Loan & Advances Header") //APNT-HR1.0
          THEN BEGIN
            Question := STRSUBSTNO(Text001 + Text002);
            CASE "Table ID" OF
              //DP6.01.01 START
              DATABASE::"Agreement Header":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Agreement Line");
              DATABASE::"Work Order Header":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Work Order Line");
              //DP6.01.01 STOP
              DATABASE::"Sales Header":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Sales Line");
              DATABASE::"Purchase Header":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Purchase Line");
              DATABASE::"Transfer Header":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Transfer Line");
              DATABASE::"Service Header":
                BEGIN
                  IF ("Document Type" = ServItemLine."Document Type"::Order) OR
                     ("Document Type" = ServItemLine."Document Type"::Quote)
                  THEN
                    NewDocDim.SETRANGE("Table ID",DATABASE::"Service Item Line")
                  ELSE
                    NewDocDim.SETRANGE("Table ID",DATABASE::"Service Line");
                END;
              DATABASE::"Service Item Line":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Service Line");
              //APNT-HR1.0
              DATABASE::"Salary Disbursments Header":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Salary Disbursments Lines");
              DATABASE::"Employee Salary Review":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Salary Review Lines");
              DATABASE::"Leave Registration":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Leave Registration Lines");
              DATABASE::"Loan & Advances Header":
                NewDocDim.SETRANGE("Table ID",DATABASE::"Loan & Advances Lines");
              //APNT-HR1.0
            END;
            NewDocDim.SETRANGE("Document Type","Document Type");
            NewDocDim.SETRANGE("Document No.","Document No.");
            NewDocDim.SETRANGE("Dimension Code","Dimension Code");
            IF FromOnDelete THEN
              IF NOT NewDocDim.FINDFIRST THEN
                EXIT;
            CASE "Table ID" OF
              //DP6.01.01 START
              DATABASE::"Agreement Header":
                BEGIN
                  AgreementLine.SETRANGE("Agreement No.","Document No.");
                  AgreementLine.SETFILTER("Element Type",'<>%1','');
                  IF AgreementLine.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Agreement Line",AgreementLine."Line No.");
                          UNTIL AgreementLine.NEXT = 0;
                      END
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Agreement Line",AgreementLine."Line No.");
                        UNTIL AgreementLine.NEXT = 0;
                    END;
                  END;
                END;

              DATABASE::"Work Order Header":
                BEGIN
                  WorkOrderLine.SETRANGE("Document No.","Document No.");
                  WorkOrderLine.SETFILTER(Code,'<>%1','');
                  IF WorkOrderLine.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Work Order Line",WorkOrderLine."Document Line No.");
                          UNTIL WorkOrderLine.NEXT = 0;
                      END
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Work Order Line",WorkOrderLine."Document Line No.");
                        UNTIL WorkOrderLine.NEXT = 0;
                    END;
                  END;
                END;
              //DP6.01.01 STOP

              DATABASE::"Sales Header":
                BEGIN
                  SalesLine.SETRANGE("Document Type","Document Type");
                  SalesLine.SETRANGE("Document No.","Document No.");
                  SalesLine.SETFILTER("No.",'<>%1','');
                  IF SalesLine.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Sales Line",SalesLine."Line No.");
                          UNTIL SalesLine.NEXT = 0;
                      END
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Sales Line",SalesLine."Line No.");
                        UNTIL SalesLine.NEXT = 0;
                    END;
                  END;
                END;
              //APNT-HR1.0
              DATABASE::"Salary Disbursments Header":
                BEGIN
                  SalDisbLines.SETRANGE("Document No.","Document No.");
                  SalDisbLines.SETFILTER("Employee No.",'<>%1','');
                  IF SalDisbLines.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Salary Disbursments Lines",SalDisbLines."Line No.");
                          UNTIL SalDisbLines.NEXT = 0;
                      END
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Salary Disbursments Lines",SalDisbLines."Line No.");
                        UNTIL SalDisbLines.NEXT = 0;
                    END;
                  END;
                END;
              DATABASE::"Employee Salary Review":
                BEGIN
                  SalReviewLines.SETRANGE("Document No.","Document No.");
                  SalReviewLines.SETFILTER("Employee No.",'<>%1','');
                  IF SalReviewLines.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Salary Review Lines",SalReviewLines."Line No.");
                          UNTIL SalReviewLines.NEXT = 0;
                      END
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Salary Review Lines",SalReviewLines."Line No.");
                        UNTIL SalReviewLines.NEXT = 0;
                    END;
                  END;
                END;
              DATABASE::"Loan & Advances Header":
                BEGIN
                  LoanAdvLines.SETRANGE("Document No.","Document No.");
                  LoanAdvLines.SETFILTER("Employee No.",'<>%1','');
                  IF LoanAdvLines.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Loan & Advances Lines",LoanAdvLines."Line No.");
                          UNTIL LoanAdvLines.NEXT = 0;
                      END
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Loan & Advances Lines",LoanAdvLines."Line No.");
                        UNTIL LoanAdvLines.NEXT = 0;
                    END;
                  END;
                END;
              DATABASE::"Leave Registration":
                BEGIN
                  EmAbsneceLines.SETFILTER("Entry No.",'%1',"Document No.");
                  EmAbsneceLines.SETFILTER("Employee No.",'<>%1','');
                  IF EmAbsneceLines.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Leave Registration Lines",EmAbsneceLines."Line No.");
                          UNTIL EmAbsneceLines.NEXT = 0;
                      END
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Leave Registration Lines",EmAbsneceLines."Line No.");
                        UNTIL EmAbsneceLines.NEXT = 0;
                    END;
                  END;
                END;
              //APNT-HR1.0

              DATABASE::"Purchase Header":
                BEGIN
                  PurchaseLine.SETRANGE("Document Type","Document Type");
                  PurchaseLine.SETRANGE("Document No.","Document No.");
                  PurchaseLine.SETFILTER("No.",'<>%1','');
                  IF PurchaseLine.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Purchase Line",PurchaseLine."Line No.");
                          UNTIL PurchaseLine.NEXT = 0;
                      END;
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Purchase Line",PurchaseLine."Line No.");
                        UNTIL PurchaseLine.NEXT = 0;
                    END;
                  END;
                END;
              DATABASE::"Transfer Header":
                BEGIN
                  TransLine.SETRANGE("Document No.","Document No.");
                  TransLine.SETRANGE("Derived From Line No.",0);
                  IF TransLine.FINDSET THEN BEGIN
                    IF GUIALLOWED THEN BEGIN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Transfer Line",TransLine."Line No.");
                          UNTIL TransLine.NEXT = 0;
                      END;
                    END ELSE BEGIN
                      NewDocDim.DELETEALL(TRUE);
                      IF NOT FromOnDelete THEN
                        REPEAT
                          InsertNew(DocDim,DATABASE::"Transfer Line",TransLine."Line No.");
                        UNTIL TransLine.NEXT = 0;
                    END;
                  END;
                END;

              DATABASE::"Service Header":
                BEGIN
                  IF ("Document Type" = "Document Type"::Order) OR
                     ("Document Type" = "Document Type"::Quote)
                  THEN BEGIN
                    ServItemLine.SETRANGE("Document Type","Document Type");
                    ServItemLine.SETRANGE("Document No.","Document No.");

                    IF ServItemLine.FIND('-') THEN
                      IF GUIALLOWED = FALSE OR (UpdateLine = UpdateLine::Update) THEN
                        UpdateDim := TRUE
                      ELSE
                        IF DIALOG.CONFIRM(Question,TRUE) THEN
                          UpdateDim := TRUE
                        ELSE
                          UpdateDim := FALSE
                    ELSE
                      UpdateDim := FALSE;

                    IF UpdateDim THEN BEGIN
                      GLSetup.GET;
                      REPEAT
                        NewDocDim.SETRANGE("Line No.",ServItemLine."Line No.");
                        IF NewDocDim.FIND('-') THEN BEGIN
                          NewDocDim.SetRecursiveValue(TRUE);
                          NewDocDim.DELETE(TRUE);
                        END;
                      UNTIL ServItemLine.NEXT = 0;

                      IF NOT FromOnDelete THEN BEGIN
                        ServItemLine.FIND('-');
                        REPEAT
                          SetRecursiveValue(TRUE);
                          InsertNew(DocDim,DATABASE::"Service Item Line",ServItemLine."Line No.");
                        UNTIL ServItemLine.NEXT = 0;
                      END;
                    END;

                    ServLine.SETRANGE("Document Type","Document Type");
                    ServLine.SETRANGE("Document No.","Document No.");
                    ServLine.SETRANGE("Service Item Line No.",0);
                    IF ServLine.FIND('-') THEN BEGIN
                      IF UpdateDim THEN BEGIN
                        NewDocDim.SETRANGE("Table ID",DATABASE::"Service Line");
                        REPEAT
                          NewDocDim.SETRANGE("Line No.",ServLine."Line No.");
                          IF NewDocDim.FIND('-') THEN BEGIN
                            NewDocDim.SetRecursiveValue(TRUE);
                            NewDocDim.DELETE(TRUE);
                          END;
                        UNTIL ServItemLine.NEXT = 0;
                        IF NOT FromOnDelete THEN BEGIN
                          ServLine.FINDFIRST;
                          REPEAT
                            SetRecursiveValue(TRUE);
                            InsertNew(DocDim,DATABASE::"Service Line",ServLine."Line No.");
                          UNTIL ServLine.NEXT = 0;
                        END;
                      END;
                    END;

                  END ELSE BEGIN
                    ServLine.SETRANGE("Document Type","Document Type");
                    ServLine.SETRANGE("Document No.","Document No.");
                    ServItemLine.SETRANGE("Document Type","Document Type");
                    ServItemLine.SETRANGE("Document No.","Document No.");

                    IF ServLine.FIND('-') OR ServItemLine.FIND('-') THEN
                      IF DIALOG.CONFIRM(Question,TRUE) THEN
                        UpdateDim := TRUE;

                    IF ServLine.FIND('-') THEN BEGIN
                      NewDocDim.SETRANGE("Table ID",DATABASE::"Service Line");
                      IF GUIALLOWED THEN BEGIN
                        IF UpdateDim THEN BEGIN
                          NewDocDim.DELETEALL(TRUE);
                          IF NOT FromOnDelete THEN
                            REPEAT
                              InsertNew(DocDim,DATABASE::"Service Line",ServLine."Line No.");
                            UNTIL ServLine.NEXT = 0;
                        END;
                      END ELSE BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Service Line",ServLine."Line No.");
                          UNTIL ServLine.NEXT = 0;
                      END;
                    END;

                    IF ServItemLine.FIND('-') THEN BEGIN
                      NewDocDim.SETRANGE("Table ID",DATABASE::"Service Item Line");
                      IF GUIALLOWED THEN BEGIN
                        IF UpdateDim THEN BEGIN
                          NewDocDim.DELETEALL(TRUE);
                          IF NOT FromOnDelete THEN
                            REPEAT
                              InsertNew(DocDim,DATABASE::"Service Item Line",ServItemLine."Line No.");
                            UNTIL ServItemLine.NEXT = 0;
                        END;
                      END ELSE BEGIN
                        NewDocDim.DELETEALL(TRUE);
                        IF NOT FromOnDelete THEN
                          REPEAT
                            InsertNew(DocDim,DATABASE::"Service Item Line",ServItemLine."Line No.");
                          UNTIL ServItemLine.NEXT = 0;
                      END;
                    END;
                  END;
                END;
              DATABASE::"Service Item Line":
                BEGIN
                  IF UpdateLine = UpdateLine::Update THEN
                    SetRecursiveValue(TRUE);
                  UpdateServLineDim(DocDim,FromOnDelete);
                END
            END;
          END;
        END;
    end;
 
    procedure GetDimensions(TableNo: Integer;DocType: Option;DocNo: Code[20];DocLineNo: Integer;var TempDocDim: Record "357")
    var
        DocDim: Record "357";
    begin
        TempDocDim.DELETEALL;

        WITH DocDim DO BEGIN
          RESET;
          SETRANGE("Table ID",TableNo);
          SETRANGE("Document Type",DocType);
          SETRANGE("Document No.",DocNo);
          SETRANGE("Line No.",DocLineNo);
          IF FINDSET THEN
            REPEAT
              TempDocDim := DocDim;
              TempDocDim.INSERT;
            UNTIL NEXT = 0;
        END;
    end;
 
    procedure UpdateAllLineDim(TableNo: Integer;DocType: Option;DocNo: Code[20];var OldDocDimHeader: Record "357")
    var
        DocDimHeader: Record "357";
        DocDimLine: Record "357";
        SalesLine: Record "37";
        PurchaseLine: Record "39";
        LineTableNo: Integer;
        ShippedReceived: Boolean;
    begin
        CASE TableNo OF
          DATABASE::"Sales Header":
            BEGIN
              LineTableNo := DATABASE::"Sales Line";
              SalesLine.SETRANGE("Document Type",DocType);
              SalesLine.SETRANGE("Document No.",DocNo);
              IF NOT SalesLine.FINDFIRST THEN
                EXIT;

              SalesLine.SETRANGE(Type,SalesLine.Type::Item);
              IF SalesLine.FINDSET THEN REPEAT
                IF SalesLine."Shipped Not Invoiced" <> 0 THEN
                  ShippedReceived := TRUE;
                IF SalesLine."Return Qty. Rcd. Not Invd." <> 0 THEN
                  ShippedReceived := TRUE;
              UNTIL (SalesLine.NEXT = 0) OR ShippedReceived;
              SalesLine.SETRANGE(Type);
            END;
          DATABASE::"Purchase Header":
            BEGIN
              LineTableNo := DATABASE::"Purchase Line";
              PurchaseLine.SETRANGE("Document Type",DocType);
              PurchaseLine.SETRANGE("Document No.",DocNo);
              IF NOT PurchaseLine.FINDFIRST THEN
                EXIT;

              PurchaseLine.SETRANGE(Type,SalesLine.Type::Item);
              IF PurchaseLine.FINDSET THEN REPEAT
                IF PurchaseLine."Qty. Rcd. Not Invoiced" <> 0 THEN
                  ShippedReceived := TRUE;
                IF PurchaseLine."Return Qty. Shipped Not Invd." <> 0 THEN
                  ShippedReceived := TRUE;
              UNTIL (PurchaseLine.NEXT = 0) OR ShippedReceived;
              PurchaseLine.SETRANGE(Type);
            END;
          DATABASE::"Service Header":
            BEGIN
              UpdateAllServLineDim(TableNo,DocType,DocNo,OldDocDimHeader,0);
              EXIT;
            END;
        END;

        DocDimHeader.SETRANGE("Table ID",TableNo);
        DocDimHeader.SETRANGE("Document Type",DocType);
        DocDimHeader.SETRANGE("Document No.",DocNo);
        DocDimHeader.SETRANGE("Line No.",0);

        DocDimLine.SETRANGE("Document Type",DocType);
        DocDimLine.SETRANGE("Document No.",DocNo);
        DocDimLine.SETFILTER("Line No.",'<>0');

        IF NOT (DocDimHeader.FINDFIRST OR OldDocDimHeader.FINDFIRST) THEN
          EXIT;

        IF UpdateLine <> UpdateLine::Update THEN
          IF GUIALLOWED THEN
            IF ShippedReceived THEN BEGIN
              IF NOT CONFIRM(Text006,TRUE) THEN
                EXIT
            END ELSE
              IF NOT CONFIRM(Text003,TRUE) THEN
                EXIT;

        // Going through all the dimensions on the Header AFTER they have been updated
        WITH DocDimHeader DO
          IF FINDSET THEN
            REPEAT
              IF NOT OldDocDimHeader.GET("Table ID","Document Type","Document No.","Line No.","Dimension Code") OR
                 (OldDocDimHeader."Dimension Value Code" <> "Dimension Value Code")
              THEN BEGIN
                DocDimLine.SETRANGE("Dimension Code","Dimension Code");
                CASE TableNo OF
                  DATABASE::"Sales Header":
                    BEGIN
                      DocDimLine.SETRANGE("Table ID",LineTableNo);
                      DocDimLine.DELETEALL(TRUE);

                      SalesLine.SETRANGE("Document Type",DocType);
                      SalesLine.SETRANGE("Document No.",DocNo);
                      IF SalesLine.FINDSET THEN
                        REPEAT
                          InsertNew(DocDimHeader,LineTableNo,SalesLine."Line No.");
                        UNTIL SalesLine.NEXT = 0;
                    END;
                  DATABASE::"Purchase Header":
                    BEGIN
                      DocDimLine.SETRANGE("Table ID",LineTableNo);
                      DocDimLine.DELETEALL(TRUE);

                      PurchaseLine.SETRANGE("Document Type",DocType);
                      PurchaseLine.SETRANGE("Document No.",DocNo);
                      IF PurchaseLine.FIND('-') THEN
                        REPEAT
                          InsertNew(DocDimHeader,LineTableNo,PurchaseLine."Line No.");
                        UNTIL PurchaseLine.NEXT = 0;
                    END;
                END;
              END;
            UNTIL NEXT = 0;

        // Going through all the dimensions on the Header BEFORE they have been updated
        // If the DimCode were there before but not anymore, all DimLines with the DimCode are deleted
        WITH OldDocDimHeader DO
          IF FIND('-') THEN
            REPEAT
              IF NOT DocDimHeader.GET("Table ID","Document Type","Document No.","Line No.","Dimension Code") THEN BEGIN
                DocDimLine.SETRANGE("Dimension Code","Dimension Code");
                DocDimLine.DELETEALL(TRUE);
              END;
            UNTIL NEXT = 0;
    end;

    local procedure InsertNew(var DocDim: Record "357";TableNo: Integer;LineNo: Integer)
    var
        NewDocDim: Record "357";
    begin
        WITH DocDim DO BEGIN
          NewDocDim."Table ID" := TableNo;
          NewDocDim."Document Type" := "Document Type";
          NewDocDim."Document No." := "Document No.";
          NewDocDim."Line No." := LineNo;
          NewDocDim."Dimension Code" := "Dimension Code";
          NewDocDim."Dimension Value Code" := "Dimension Value Code";
          IF UpdateLine = UpdateLine::Update THEN
            NewDocDim.SetRecursiveValue(TRUE)
          ELSE
            IF UpdateLine = UpdateLine::DoNotUpdate THEN
              NewDocDim.SetRecursiveValue(FALSE);
          NewDocDim.INSERT(TRUE);
        END;
    end;
 
    procedure OnDeleteServRec()
    begin
        GLSetup.GET;
        UpdateLineDim(Rec,TRUE);
        IF "Dimension Code" = GLSetup."Global Dimension 1 Code" THEN
          UpdateGlobalDimCode(
            1,"Table ID","Document Type","Document No.","Line No.",'');
        IF "Dimension Code" = GLSetup."Global Dimension 2 Code" THEN
          UpdateGlobalDimCode(
            2,"Table ID","Document Type","Document No.","Line No.",'');
    end;
 
    procedure UpdateServLineDim(var DocDim: Record "357";FromOnDelete: Boolean)
    var
        NewDocDim: Record "357";
        ServLine: Record "5902";
        ServItemLine: Record "5901";
        Question: Text[250];
        UpdateDim: Boolean;
    begin
        WITH DocDim DO BEGIN
          IF "Table ID" = DATABASE::"Service Item Line" THEN BEGIN
            Question := STRSUBSTNO(Text001 + Text002);
            NewDocDim.SETRANGE("Table ID",DATABASE::"Service Line");
            NewDocDim.SETRANGE("Document Type","Document Type");
            NewDocDim.SETRANGE("Document No.","Document No.");
            NewDocDim.SETRANGE("Dimension Code","Dimension Code");

            IF FromOnDelete THEN
              IF NOT NewDocDim.FIND('-') THEN
                EXIT;

            ServItemLine.SETRANGE("Document Type","Document Type");
            ServItemLine.SETRANGE("Document No.","Document No.");
            ServItemLine.SETRANGE("Line No.","Line No.");

            IF ServItemLine.FIND('-') THEN BEGIN

              ServLine.SETRANGE("Document Type","Document Type");
              ServLine.SETRANGE("Document No.","Document No.");
              ServLine.SETRANGE("Service Item Line No.",ServItemLine."Line No.");
              IF ServLine.FIND('-') THEN BEGIN
                IF GUIALLOWED = FALSE OR (UpdateLine = UpdateLine::Update) THEN
                  UpdateDim := TRUE;

                IF UpdateDim = FALSE THEN
                  IF DIALOG.CONFIRM(Question,TRUE) THEN BEGIN
                    SetRecursiveValue(TRUE);
                    UpdateDim := TRUE;
                  END ELSE
                    SetRecursiveValue(FALSE);

                IF UpdateDim THEN BEGIN
                  ServLine.FIND('-');
                  REPEAT
                    NewDocDim.SETRANGE("Line No.",ServLine."Line No.");
                    IF NewDocDim.FIND('-') THEN BEGIN
                      NewDocDim.SetRecursiveValue(TRUE);
                      NewDocDim.DELETEALL(TRUE);
                    END;
                  UNTIL ServLine.NEXT = 0;
                  IF NOT FromOnDelete THEN BEGIN
                    ServLine.FIND('-');
                    REPEAT
                      SetRecursiveValue(TRUE);
                      InsertNew(DocDim,DATABASE::"Service Line",ServLine."Line No.");
                    UNTIL ServLine.NEXT = 0;
                  END;
                END;
              END;
            END;
          END;
        END;
    end;
 
    procedure SetRecursiveValue(Recursive: Boolean)
    begin
        IF Recursive THEN
          UpdateLine := UpdateLine::Update
        ELSE
          UpdateLine := UpdateLine::DoNotUpdate;
    end;
 
    procedure UpdateAllServLineDim(TableNo: Integer;DocType: Option;DocNo: Code[20];var OldDocDimHeader: Record "357";DocLineNo: Integer)
    var
        DocDimHeader: Record "357";
        DocDimLine: Record "357";
        ServLine: Record "5902";
        ServItemLine: Record "5901";
    begin
        CASE TableNo OF
          DATABASE::"Service Header":
            BEGIN
              ServLine.SETRANGE("Document Type",DocType);
              ServLine.SETRANGE("Document No.",DocNo);
              ServItemLine.SETRANGE("Document Type",DocType);
              ServItemLine.SETRANGE("Document No.",DocNo);
              IF NOT ServLine.FIND('-') AND NOT ServItemLine.FIND('-') THEN
                EXIT;
            END;
          DATABASE::"Service Item Line":
            BEGIN
              ServItemLine.SETRANGE("Document Type",DocType);
              ServItemLine.SETRANGE("Document No.",DocNo);
              ServItemLine.SETRANGE("Line No.",DocLineNo);
              IF ServItemLine.FINDFIRST THEN;

              ServLine.SETRANGE("Document Type",DocType);
              ServLine.SETRANGE("Document No.",DocNo);
              ServLine.SETRANGE("Service Item Line No.",ServItemLine."Line No.");
              IF NOT ServLine.FIND('-') THEN
                EXIT;

              DocDimLine.SETRANGE("Table ID",DATABASE::"Service Line");
            END;
          ELSE
            EXIT;
        END;

        DocDimHeader.SETRANGE("Table ID",TableNo);
        DocDimHeader.SETRANGE("Document Type",DocType);
        DocDimHeader.SETRANGE("Document No.",DocNo);
        DocDimHeader.SETRANGE("Line No.",DocLineNo);

        DocDimLine.SETRANGE("Document Type",DocType);
        DocDimLine.SETRANGE("Document No.",DocNo);


        IF NOT (DocDimHeader.FIND('-') OR OldDocDimHeader.FIND('-')) THEN
          EXIT;

        IF UpdateLine <> UpdateLine::Update THEN
          IF GUIALLOWED THEN
            IF NOT CONFIRM(Text003,TRUE) THEN
              EXIT;

        // Going through all the dimensions on the Header AFTER they have been updated
        WITH DocDimHeader DO
          IF FIND('-') THEN
            REPEAT
              IF NOT OldDocDimHeader.GET("Table ID","Document Type","Document No.","Line No.","Dimension Code") OR
                 (OldDocDimHeader."Dimension Value Code" <> "Dimension Value Code")
              THEN BEGIN
                DocDimLine.SETRANGE("Dimension Code","Dimension Code");
                CASE TableNo OF
                  DATABASE::"Service Header":
                    BEGIN
                      DocDimLine.SETFILTER("Line No.",'<>0');
                      DocDimLine.SETRANGE("Table ID",DATABASE::"Service Item Line");
                      IF DocDimLine.FINDSET THEN
                        REPEAT
                          DocDimLine.SetRecursiveValue(TRUE);
                          DocDimLine.DELETE(TRUE);
                        UNTIL DocDimLine.NEXT = 0;

                      DocDimLine.SETRANGE("Table ID",DATABASE::"Service Line");
                      IF DocDimLine.FIND('-') THEN
                        REPEAT
                          DocDimLine.SetRecursiveValue(TRUE);
                          DocDimLine.DELETE(TRUE);
                        UNTIL DocDimLine.NEXT = 0;

                      IF (DocType = ServLine."Document Type"::Order) OR
                         (DocType = ServLine."Document Type"::Quote)
                      THEN BEGIN
                        IF ServItemLine.FIND('-') THEN
                          REPEAT
                            Rec.SetRecursiveValue(TRUE);
                            InsertNew(DocDimHeader,DATABASE::"Service Item Line",ServItemLine."Line No.");
                          UNTIL ServItemLine.NEXT = 0;
                        ServLine.SETRANGE("Service Item Line No.",0);
                        IF ServLine.FIND('-') THEN
                          REPEAT
                            Rec.SetRecursiveValue(TRUE);
                            InsertNew(DocDimHeader,DATABASE::"Service Line",ServLine."Line No.");
                          UNTIL ServLine.NEXT = 0;
                      END ELSE
                        IF ServLine.FIND('-') THEN
                          REPEAT
                            Rec.SetRecursiveValue(TRUE);
                            InsertNew(DocDimHeader,DATABASE::"Service Line",ServLine."Line No.");
                          UNTIL ServLine.NEXT = 0;
                    END;
                  DATABASE::"Service Item Line":
                    BEGIN
                      IF ServItemLine.FINDFIRST THEN
                        REPEAT
                          ServLine.SETRANGE("Service Item Line No.",ServItemLine."Line No.");
                          IF ServLine.FIND('-') THEN BEGIN
                            REPEAT
                              DocDimLine.SETRANGE("Line No.",ServLine."Line No.");
                              IF DocDimLine.FIND('-') THEN
                                REPEAT
                                  Rec.SetRecursiveValue(TRUE);
                                  DocDimLine.DELETE(TRUE);
                                UNTIL DocDimLine.NEXT = 0;
                            UNTIL ServLine.NEXT = 0;

                            ServLine.FIND('-');
                            REPEAT
                              Rec.SetRecursiveValue(TRUE);
                              InsertNew(DocDimHeader,DATABASE::"Service Line",ServLine."Line No.");
                            UNTIL ServLine.NEXT = 0;
                          END;
                        UNTIL ServItemLine.NEXT = 0;
                    END;
                END;
              END;
            UNTIL NEXT = 0;

        // Going through all the dimensions on the Header BEFORE they have been updated
        // If the DimCode were there before but not anymore, all DimLines with the DimCode are deleted
        WITH OldDocDimHeader DO
          IF FINDSET THEN
            REPEAT
              IF NOT DocDimHeader.GET("Table ID","Document Type","Document No.","Line No.","Dimension Code") THEN BEGIN
                DocDimLine.SETRANGE("Dimension Code","Dimension Code");
                DocDimLine.SetRecursiveValue(TRUE);
                DocDimLine.DELETEALL(TRUE);
              END;
            UNTIL NEXT = 0;
    end;
 
    procedure VerifyLineDim(var DocDim: Record "357")
    var
        SalesLine: Record "37";
        PurchaseLine: Record "39";
    begin
        CASE "Table ID" OF
          DATABASE::"Sales Line":
            BEGIN
              IF SalesLine.GET(DocDim."Document Type",DocDim."Document No.",DocDim."Line No.") THEN
                IF (SalesLine."Qty. Shipped Not Invoiced" <> 0) OR (SalesLine."Return Rcd. Not Invd." <> 0) THEN
                  IF NOT CONFIRM(Text004,TRUE,SalesLine.TABLECAPTION) THEN
                    ERROR(Text005)
            END;
          DATABASE::"Purchase Line":
            BEGIN
              IF PurchaseLine.GET(DocDim."Document Type",DocDim."Document No.",DocDim."Line No.") THEN
                IF (PurchaseLine."Qty. Rcd. Not Invoiced" <> 0) OR (PurchaseLine."Return Qty. Shipped Not Invd." <> 0) THEN

                  IF NOT CONFIRM(Text004,TRUE,PurchaseLine.TABLECAPTION) THEN
                    ERROR(Text005)
            END;
        END;
    end;
}


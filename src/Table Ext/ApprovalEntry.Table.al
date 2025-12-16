table 454 "Approval Entry"
{
    // DP = changes made by DVS
    // T044145      Sujith     02.08.22       Added for CRF_22_0859

    Caption = 'Approval Entry';

    fields
    {
        field(1; "Table ID"; Integer)
        {
            Caption = 'Table ID';
        }
        field(2; "Document Type"; Option)
        {
            Caption = 'Document Type';
            Description = 'DP6.01.01,PV-1.0 - Added Option Journal Voucher';
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order,Lease,Sale,Work Order,Journal Voucher';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order",Lease,Sale,"Work Order","Journal Voucher";
        }
        field(3; "Document No."; Code[20])
        {
            Caption = 'Document No.';
        }
        field(4; "Sequence No."; Integer)
        {
            Caption = 'Sequence No.';
        }
        field(5; "Approval Code"; Code[20])
        {
            Caption = 'Approval Code';
        }
        field(6; "Sender ID"; Code[20])
        {
            Caption = 'Sender ID';
        }
        field(7; "Salespers./Purch. Code"; Code[10])
        {
            Caption = 'Salespers./Purch. Code';
        }
        field(8; "Approver ID"; Code[20])
        {
            Caption = 'Approver ID';
        }
        field(9; Status; Option)
        {
            Caption = 'Status';
            OptionCaption = 'Created,Open,Canceled,Rejected,Approved';
            OptionMembers = Created,Open,Canceled,Rejected,Approved;
        }
        field(10; "Date-Time Sent for Approval"; DateTime)
        {
            Caption = 'Date-Time Sent for Approval';
        }
        field(11; "Last Date-Time Modified"; DateTime)
        {
            Caption = 'Last Date-Time Modified';
        }
        field(12; "Last Modified By ID"; Code[20])
        {
            Caption = 'Last Modified By ID';
        }
        field(13; Comment; Boolean)
        {
            CalcFormula = Exist("Approval Comment Line" WHERE(Table ID=FIELD(Table ID),
                                                               Document Type=FIELD(Document Type),
                                                               Document No.=FIELD(Document No.)));
            Caption = 'Comment';
            Editable = false;
            FieldClass = FlowField;
        }
        field(14;"Due Date";Date)
        {
            Caption = 'Due Date';
        }
        field(15;Amount;Decimal)
        {
            AutoFormatExpression = "Currency Code";
            AutoFormatType = 1;
            Caption = 'Amount';
        }
        field(16;"Amount (LCY)";Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Amount (LCY)';
        }
        field(17;"Currency Code";Code[10])
        {
            Caption = 'Currency Code';
            TableRelation = Currency;
        }
        field(18;"Approval Type";Option)
        {
            Caption = 'Approval Type';
            OptionCaption = ' ,Sales Pers./Purchaser,Approver';
            OptionMembers = " ","Sales Pers./Purchaser",Approver;
        }
        field(19;"Limit Type";Option)
        {
            Caption = 'Limit Type';
            OptionCaption = 'Approval Limits,Credit Limits,Request Limits,No Limits';
            OptionMembers = "Approval Limits","Credit Limits","Request Limits","No Limits";
        }
        field(20;"Available Credit Limit (LCY)";Decimal)
        {
            Caption = 'Available Credit Limit (LCY)';
        }
    }

    keys
    {
        key(Key1;"Table ID","Document Type","Document No.","Sequence No.")
        {
            Clustered = true;
        }
        key(Key2;"Approver ID",Status)
        {
        }
        key(Key3;"Sender ID")
        {
        }
    }

    fieldgroups
    {
    }
 
    procedure ShowDocument()
    var
        SalesHeader: Record "36";
        PurchHeader: Record "38";
        GenJnlHeader: Record "50085";
        GLSetup: Record "98";
        rVendor: Record "23";
    begin
        CASE "Table ID" OF
          DATABASE::"Sales Header":
            BEGIN
              IF NOT SalesHeader.GET("Document Type","Document No.") THEN
                EXIT;
              CASE "Document Type" OF
                "Document Type"::Quote:
                  FORM.RUN(FORM::"Sales Quote",SalesHeader);
                "Document Type"::Order:
                  FORM.RUN(FORM::"Sales Order",SalesHeader);
                "Document Type"::Invoice:
                  FORM.RUN(FORM::"Sales Invoice",SalesHeader);
                "Document Type"::"Credit Memo":
                  FORM.RUN(FORM::"Sales Credit Memo",SalesHeader);
                "Document Type"::"Blanket Order":
                  FORM.RUN(FORM::"Blanket Sales Order",SalesHeader);
                "Document Type"::"Return Order":
                  FORM.RUN(FORM::"Sales Return Order",SalesHeader);
              END;
            END;
          DATABASE::"Purchase Header":
            BEGIN
              IF NOT PurchHeader.GET("Document Type","Document No.") THEN
                EXIT;
              CASE "Document Type" OF
                "Document Type"::Quote:
                  FORM.RUN(FORM::"Purchase Quote",PurchHeader);
                "Document Type"::Order:
                  FORM.RUN(FORM::"Purchase Order",PurchHeader);
                "Document Type"::Invoice:
                  FORM.RUN(FORM::"Purchase Invoice",PurchHeader);
                "Document Type"::"Credit Memo":
                  FORM.RUN(FORM::"Purchase Credit Memo",PurchHeader);
                "Document Type"::"Blanket Order":
                  FORM.RUN(FORM::"Blanket Purchase Order",PurchHeader);
                "Document Type"::"Return Order":
                  FORM.RUN(FORM::"Purchase Return Order",PurchHeader);
              END;
            END;
          //APNT-PV1.0 +
          DATABASE::"Gen. Jnl Header":
            BEGIN
              GLSetup.GET;
              IF NOT GenJnlHeader.GET(GLSetup."Payment Voucher Template",GLSetup."Payment Voucher Batch","Document No.") THEN
                EXIT;
              FORM.RUN(FORM::"Payment Voucher Card",GenJnlHeader);
            END;
          //APNT-PV1.0 -
          //T044145 +
          DATABASE::Vendor:
            BEGIN
              CLEAR(rVendor);
              IF NOT rVendor.GET("Document No.") THEN
                EXIT;
              FORM.RUN(FORM::"Vendor Card",rVendor);
            END;
          //T044145 -
          ELSE
            EXIT;
        END;
    end;
}


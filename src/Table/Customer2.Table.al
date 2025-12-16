table 50065 Customer2
{
    Caption = 'Customer';
    DrillDownFormID = Form22;
    LookupFormID = Form22;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(20; "Credit Limit (LCY)"; Decimal)
        {
            AutoFormatType = 1;
            Caption = 'Credit Limit (LCY)';
        }
        field(39; Blocked; Option)
        {
            Caption = 'Blocked';
            OptionCaption = ' ,Ship,Invoice,All';
            OptionMembers = " ",Ship,Invoice,All;
        }
    }

    keys
    {
        key(Key1; "No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Field2, Field7, Field91, Field9, Field8)
        {
        }
    }

    trigger OnDelete()
    var
        CampaignTargetGr: Record "Campaign Target Group";
        ContactBusRel: Record "Contact Business Relation";
        Job: Record Job;
        CampaignTargetGrMgmt: Codeunit "Campaign Target Group Mgt.";
        StdCustSalesCode: Record "Standard Customer Sales Code";
    begin
    end;

    var
        Text000: Label 'You cannot delete %1 %2 because there is at least one outstanding Sales %3 for this customer.';
        Text002: Label 'Do you wish to create a contact for %1 %2?';
        SalesSetup: Record "Sales & Receivables Setup";
        CommentLine: Record "Comment Line";
        SalesOrderLine: Record "Sales Line";
        CustBankAcc: Record "Customer Bank Account";
        ShipToAddr: Record "Ship-to Address";
        PostCode: Record "Post Code";
        GenBusPostingGrp: Record "Gen. Business Posting Group";
        ShippingAgentService: Record "Shipping Agent Services";
        ItemCrossReference: Record "Item Cross Reference";
        RMSetup: Record "Marketing Setup";
        SalesPrice: Record "Sales Price";
        SalesLineDisc: Record "Sales Line Discount";
        SalesPrepmtPct: Record "Sales Prepayment %";
        ServContract: Record "Service Contract";
        ServHeader: Record "Service Header";
        ServiceItem: Record "Service Item";
        NoSeriesMgt: Codeunit "396";
        MoveEntries: Codeunit "361";
        UpdateContFromCust: Codeunit "5056";
        DimMgt: Codeunit "408";
        MobSalesmgt: Codeunit "8726";
        InsertFromContact: Boolean;
        Text003: Label 'Contact %1 %2 is not related to customer %3 %4.';
        Text004: Label 'post';
        Text005: Label 'create';
        Text006: Label 'You cannot %1 this type of document when Customer %2 is blocked with type %3';
        Text007: Label 'You cannot delete %1 %2 because there is at least one not cancelled Service Contract for this customer.';
        Text008: Label 'Deleting the %1 %2 will cause the %3 to be deleted for the associated Service Items. Do you want to continue?';
        Text009: Label 'Cannot delete customer.';
        Text010: Label 'The %1 %2 has been assigned to %3 %4.\The same %1 cannot be entered on more than one %3. Enter another code.';
        Text011: Label 'Reconciling IC transactions may be difficult if you change IC Partner Code because this %1 has ledger entries in a fiscal year that has not yet been closed.\ Do you still want to change the IC Partner Code?';
        Text012: Label 'You cannot change the contents of the %1 field because this %2 has one or more open ledger entries.';
        Text013: Label 'You cannot delete %1 %2 because there is at least one outstanding Service %3 for this customer.';
        Text014: Label 'Before you can use Online Map, you must fill in the Online Map Setup window.\See Setting Up Online Map in Help.';
        Text015: Label 'You cannot delete %1 %2 because there is at least one %3 associated to this customer.';

    procedure AssistEdit(OldCust: Record Customer): Boolean
    var
        Cust: Record Customer;
    begin
    end;

    procedure ValidateShortcutDimCode(FieldNumber: Integer; var ShortcutDimCode: Code[20])
    begin
    end;

    procedure ShowContact()
    var
        ContBusRel: Record "Contact Business Relation";
        Cont: Record Contact;
    begin
    end;

    procedure SetInsertFromContact(FromContact: Boolean)
    begin
    end;

    procedure CheckBlockedCustOnDocs(Cust2: Record Customer; DocType: Option Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order"; Shipment: Boolean; Transaction: Boolean)
    begin
    end;

    procedure CheckBlockedCustOnJnls(Cust2: Record Customer; DocType: Option " ",Payment,Invoice,"Credit Memo","Finance Charge",Reminder,Refund; Transaction: Boolean)
    begin
    end;

    procedure CustBlockedErrorMessage(Cust2: Record Customer; Transaction: Boolean)
    var
        "Action": Text[30];
    begin
    end;

    procedure LookUpAdjmtValueEntries(CustDateFilter: Text[30])
    var
        ValueEntry: Record "Value Entry";
    begin
    end;

    procedure DisplayMap()
    var
        MapPoint: Record "Map Point";
        MapMgt: Codeunit "802";
    begin
    end;

    procedure CreateAction(Type: Integer)
    var
        RecRef: RecordRef;
        xRecRef: RecordRef;
        ActionsMgt: Codeunit "99001451";
    begin
    end;

    procedure AssistEditClient(OldCust: Record Customer): Boolean
    var
        Cust: Record Customer;
        PremiseMgt: Record "Premise Management Setup";
    begin
    end;
}


table 33016825 "Work Order Line"
{
    // LG00.02 20032014 Added Field "Task Classification"
    //         Change Table Relation for Code Field

    Caption = 'Work Order Line';

    fields
    {
        field(1; "Document Type"; Option)
        {
            OptionCaption = 'Work Order';
            OptionMembers = "Work Order";
        }
        field(2; "Document No."; Code[20])
        {
            TableRelation = "Work Order Header".No.;
        }
        field(3; "Document Line No."; Integer)
        {
        }
        field(4; Type; Option)
        {
            OptionCaption = ' ,Task,Fixed Asset';
            OptionMembers = " ",Task,"Fixed Asset";

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF Type <> xRec.Type THEN BEGIN
                    Code := '';
                    UpdateLineDetails;
                END;
            end;
        }
        field(5; "Code"; Code[20])
        {
            TableRelation = IF (Type = FILTER(Fixed Asset)) "Fixed Asset".No.
                            ELSE IF (Type=FILTER(Task)) "Task Code".Code WHERE (Task Classification=FIELD(Task Classification));

            trigger OnValidate()
            begin
                TestStatusOpen;
                //IF Code <> xRec.Code THEN
                UpdateLineDetails;
            end;
        }
        field(6;Description;Text[50])
        {

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(7;Quantity;Decimal)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                VALIDATE("Cost Amount",Quantity * "Unit Cost");
                VALIDATE("Sales Amount",Quantity * "Unit Price");
            end;
        }
        field(8;"Unit of Measure Code";Code[10])
        {
            TableRelation = "Unit of Measure".Code;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(9;"Unit Cost";Decimal)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                VALIDATE("Cost Amount",Quantity * "Unit Cost");
            end;
        }
        field(10;"Cost Amount";Decimal)
        {
            MinValue = 0;

            trigger OnValidate()
            var
                WorkOrderHeader: Record "Work Order Header";
                Currency: Record Currency;
            begin
                TestStatusOpen;
                "Cost Amount":=Quantity * "Unit Cost";
                CLEAR(WorkOrderHeader);
                WorkOrderHeader.GET("Document Type","Document No.");
                IF WorkOrderHeader."Currency Code" <> '' THEN BEGIN
                   IF Currency.GET(WorkOrderHeader."Currency Code") THEN;
                  "Cost Amount(LCY)" := ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,WorkOrderHeader."Currency Code",
                    "Cost Amount",WorkOrderHeader."Currency Factor"),Currency."Unit-Amount Rounding Precision")
                END ELSE
                  "Cost Amount(LCY)" := "Cost Amount";
                "Currency Code":=WorkOrderHeader."Currency Code";
            end;
        }
        field(11;"Document Date";Date)
        {
        }
        field(12;"Convert to Purch. Doc Type";Option)
        {
            OptionCaption = ' ,Quote,Order,Invoice';
            OptionMembers = " ",Quote,"Order",Invoice;
        }
        field(13;"Vendor No.";Code[20])
        {
            TableRelation = Vendor;

            trigger OnValidate()
            var
                VendorRec: Record Vendor;
            begin
                IF "Vendor No." <> '' THEN BEGIN
                  VendorRec.GET("Vendor No.");
                  "Vendor Name" := VendorRec.Name;
                END ELSE
                  CLEAR("Vendor Name");
            end;
        }
        field(14;"Vendor Name";Text[50])
        {
        }
        field(15;"Converted Purch. Doc No.";Code[20])
        {
        }
        field(16;"Converted Purch. Doc Line No.";Integer)
        {
        }
        field(17;"Converted Purch. Doc Datetime";DateTime)
        {
        }
        field(19;Selection;Boolean)
        {
        }
        field(20;"Converted Sales. Doc Type";Option)
        {
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(21;"Converted Sales. Doc No.";Code[20])
        {
        }
        field(22;"Converted Sales. Doc Line No.";Integer)
        {
        }
        field(23;"Converted Sales. Doc Datetime";DateTime)
        {
        }
        field(24;"Assigned Resource No.";Code[20])
        {
            TableRelation = "Work Order Resource"."Resource No." WHERE (Work Order No.=FIELD(Document No.));

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(25;"Shortcut Dimension 1 Code";Code[20])
        {
            CaptionClass = '1,2,1';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1,"Shortcut Dimension 1 Code");
            end;
        }
        field(26;"Shortcut Dimension 2 Code";Code[20])
        {
            CaptionClass = '1,2,2';
            TableRelation = "Dimension Value".Code WHERE (Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2,"Shortcut Dimension 2 Code");
            end;
        }
        field(27;"Convert to Sales Doc Type";Option)
        {
            OptionCaption = ' ,Quote,Order,Invoice';
            OptionMembers = " ",Quote,"Order",Invoice;
        }
        field(28;"Event No.";Code[20])
        {
            TableRelation = "Event Detail".No.;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(29;"Facility No.";Code[20])
        {
            TableRelation = "Facility Type".Code;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(30;"Client No.";Code[20])
        {

            trigger OnLookup()
            var
                FacilityRec: Record Facility;
                PremiseRec: Record Premise;
                ClientRec: Record Customer;
                ClientList: Form "33016840";
            begin
                WorkHeader.GET("Document Type","Document No.");
                IF WorkHeader."Request From" = WorkHeader."Request From"::Facility THEN BEGIN
                  IF FacilityRec.GET(WorkHeader."Premise/Facility No.") THEN BEGIN
                    IF (FacilityRec."Linked Premise Code" <> '') AND PremiseRec.GET(FacilityRec."Linked Premise Code") THEN BEGIN
                      CLEAR(ClientList);
                      ClientRec.RESET;
                      ClientRec.SETRANGE("No.",PremiseRec."Client No.");
                      ClientList.SETTABLEVIEW(ClientRec);
                      ClientList.SETRECORD(ClientRec);
                      ClientList.EDITABLE(FALSE);
                      ClientList.LOOKUPMODE(TRUE);
                      IF ClientList.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        ClientList.GETRECORD(ClientRec);
                        VALIDATE("Client No.",ClientRec."No.");
                      END;
                    END ELSE BEGIN
                      CLEAR(ClientList);
                      ClientRec.RESET;
                      ClientRec.SETCURRENTKEY(ClientRec."No.");
                      ClientList.SETTABLEVIEW(ClientRec);
                      ClientList.SETRECORD(ClientRec);
                      ClientList.EDITABLE(FALSE);
                      ClientList.LOOKUPMODE(TRUE);
                      IF ClientList.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        ClientList.GETRECORD(ClientRec);
                        VALIDATE("Client No.",ClientRec."No.");
                      END;
                    END;
                  END;
                END ELSE
                IF WorkHeader."Request From" = WorkHeader."Request From"::Premise THEN BEGIN
                  IF PremiseRec.GET(WorkHeader."Premise/Facility No.") THEN BEGIN
                    IF (PremiseRec."Client No." <> '') THEN BEGIN
                      CLEAR(ClientList);
                      ClientRec.RESET;
                      ClientRec.SETRANGE("No.",PremiseRec."Client No.");
                      ClientList.SETTABLEVIEW(ClientRec);
                      ClientList.SETRECORD(ClientRec);
                      ClientList.EDITABLE(FALSE);
                      ClientList.LOOKUPMODE(TRUE);
                      IF ClientList.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        ClientList.GETRECORD(ClientRec);
                        VALIDATE("Client No.",ClientRec."No.");
                      END;
                    END ELSE BEGIN
                      CLEAR(ClientList);
                      ClientRec.RESET;
                      ClientRec.SETCURRENTKEY(ClientRec."No.");
                      ClientList.SETTABLEVIEW(ClientRec);
                      ClientList.SETRECORD(ClientRec);
                      ClientList.EDITABLE(FALSE);
                      ClientList.LOOKUPMODE(TRUE);
                      IF ClientList.RUNMODAL = ACTION::LookupOK THEN BEGIN
                        ClientList.GETRECORD(ClientRec);
                        VALIDATE("Client No.",ClientRec."No.");
                      END;
                    END;
                  END;
                END;
            end;
        }
        field(31;"Unit Price";Decimal)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                VALIDATE("Sales Amount",Quantity * "Unit Price");
            end;
        }
        field(32;"Sales Amount";Decimal)
        {
            MinValue = 0;

            trigger OnValidate()
            var
                WorkOrderHeader: Record "Work Order Header";
                Currency: Record Currency;
            begin
                TestStatusOpen;
                "Sales Amount" := Quantity * "Unit Price";
                WorkOrderHeader.GET("Document Type","Document No.");
                IF WorkOrderHeader."Currency Code" <> '' THEN BEGIN
                  IF Currency.GET(WorkOrderHeader."Currency Code") THEN
                  "Sales Amount(LCY)" :=ROUND(CurrExchRate.ExchangeAmtLCYToFCY(WORKDATE,WorkOrderHeader."Currency Code",
                    "Sales Amount",WorkOrderHeader."Currency Factor"),Currency."Unit-Amount Rounding Precision")
                END ELSE
                  "Sales Amount(LCY)" := "Sales Amount";
            end;
        }
        field(33;"Converted Purch. Doc Type";Option)
        {
            OptionCaption = 'Quote,Order,Invoice,Credit Memo,Blanket Order,Return Order';
            OptionMembers = Quote,"Order",Invoice,"Credit Memo","Blanket Order","Return Order";
        }
        field(34;"Currency Code";Code[10])
        {
        }
        field(35;"Cost Amount(LCY)";Decimal)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(36;"Sales Amount(LCY)";Decimal)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
            end;
        }
        field(37;"Source Code";Code[20])
        {
        }
        field(38;"Planned Date";Date)
        {
            Editable = false;
        }
        field(39;"No. of Resources";Integer)
        {
            MinValue = 0;

            trigger OnValidate()
            begin
                TestStatusOpen;
                IF "No. of Resources" <> xRec."No. of Resources" THEN
                  "Allocation Entries Created" := FALSE;
            end;
        }
        field(40;"Allocation Entries Created";Boolean)
        {
            Caption = 'Allocation Entries Created';
            Editable = false;
        }
        field(41;"Task Type";Option)
        {
            Editable = false;
            OptionCaption = ' ,Labour,Material';
            OptionMembers = " ",Labour,Material;
        }
        field(42;"Task Classification";Option)
        {
            Description = 'LG00.02';
            OptionCaption = ' ,Chargable,Non-Chargable,Projects';
            OptionMembers = " ",Chargable,"Non-Chargable",Projects;
        }
    }

    keys
    {
        key(Key1;"Document Type","Document No.","Document Line No.")
        {
            Clustered = true;
        }
        key(Key2;"Document Type","Document No.","Convert to Purch. Doc Type","Vendor No.")
        {
        }
        key(Key3;"Document Type","Document No.","Convert to Sales Doc Type","Client No.")
        {
            SumIndexFields = "Sales Amount";
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    begin
        TestStatusOpen;
        IF "Converted Purch. Doc No." <> '' THEN
          ERROR(Text001,"Document Type","Document No.");
        IF "Converted Sales. Doc No." <> '' THEN
          ERROR(Text002,"Document Type","Document No.");

        DimMgt.DeleteDocDim(DATABASE::"Work Order Line","Document Type","Document No.","Document Line No.");

        DeleteWOResourceAllocation;
    end;

    trigger OnInsert()
    var
        DocDim: Record "Document Dimension";
    begin
        WorkHeader.GET("Document Type","Document No.");
        "Document Date" := WorkHeader."Document Date";

        DocDim.LOCKTABLE;
        DimMgt.InsertDocDim(
          DATABASE::"Work Order Line","Document Type","Document No.","Document Line No.",
          "Shortcut Dimension 1 Code","Shortcut Dimension 2 Code");
    end;

    var
        DimMgt: Codeunit "408";
        WorkHeader: Record "Work Order Header";
        Text001: Label 'Purchase Document have been created from Work Order Type : %1 No. : %2.';
        Text002: Label 'Sales Document have been created from Work Order Type : %1 No. : %2.';
        CurrExchRate: Record "Currency Exchange Rate";
        Text003: Label 'Client No. must be %1 in Work Order Line %2 for Work Order No. %3';
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        IF "Document Line No." <> 0 THEN BEGIN
          DimMgt.SaveDocDim(
            DATABASE::"Work Order Line","Document Type","Document No.",
            "Document Line No.",FieldNumber,ShortcutDimCode);
          MODIFY;
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure LookupShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber,ShortcutDimCode);
        IF "Document Line No." <> 0 THEN BEGIN
          DimMgt.SaveDocDim(
            DATABASE::"Work Order Line","Document Type","Document No.",
            "Document Line No.",FieldNumber,ShortcutDimCode);
          MODIFY;
        END ELSE
          DimMgt.SaveTempDim(FieldNumber,ShortcutDimCode);
    end;
 
    procedure ShowDimensions()
    var
        DocDim: Record "Document Dimension";
        DocDimensions: Form "546";
    begin
        TESTFIELD("Document No.");
        TESTFIELD("Document Line No.");
        DocDim.SETRANGE("Table ID",DATABASE::"Work Order Line");
        DocDim.SETRANGE("Document No.","Document No.");
        DocDim.SETRANGE("Line No.","Document Line No.");
        DocDimensions.SETTABLEVIEW(DocDim);
        DocDimensions.RUNMODAL;
    end;
 
    procedure UpdateDimensions()
    begin
        WorkHeader.GET("Document Type","Document No.");
        "Shortcut Dimension 1 Code" := WorkHeader."Shortcut Dimension 1 Code";
        "Shortcut Dimension 2 Code" := WorkHeader."Shortcut Dimension 2 Code";
    end;
 
    procedure UpdateLineDetails()
    var
        FixedAsset: Record "Fixed Asset";
        TaskCode: Record "Task Code";
    begin
        WorkHeader.GET("Document Type","Document No.");
        CASE Type OF
          Type::" ":
            BEGIN
              Code := '';
              ClearLineDetails;
            END;
          Type::Task:
            BEGIN
              IF Code <> '' THEN BEGIN
                TaskCode.GET(Code);
                Description := TaskCode.Description;
                VALIDATE("Unit Cost",TaskCode."Task Cost");
                VALIDATE("Unit Price",TaskCode."Task Price");
                VALIDATE("Vendor No.",TaskCode."Vendor No.");
                VALIDATE(Quantity,TaskCode.Quantity);
                VALIDATE("Task Type",TaskCode."Task Type");
                VALIDATE("Unit of Measure Code",TaskCode."Unit of Measure");
               "Client No." := WorkHeader."Client No."
              END ELSE
                ClearLineDetails;
            END;
          Type::"Fixed Asset":
            BEGIN
              IF Code <> '' THEN BEGIN
                FixedAsset.GET(Code);
                Description := FixedAsset.Description;
                "Shortcut Dimension 1 Code" := FixedAsset."Global Dimension 1 Code";
                "Shortcut Dimension 2 Code" := FixedAsset."Global Dimension 2 Code";
                VALIDATE(Quantity,1);
                VALIDATE("Vendor No.",FixedAsset."Vendor No.");
               "Client No." := WorkHeader."Client No."
              END ELSE
                ClearLineDetails;
            END;
        END;
    end;
 
    procedure ClearLineDetails()
    begin
        Description := '';
        "Unit Cost" := 0;
        "Unit Price" := 0;
        "Cost Amount" := 0;
        "Sales Amount" := 0;
        Quantity := 0;
        "Unit of Measure Code" := '';
        "Shortcut Dimension 1 Code" := '';
        "Shortcut Dimension 2 Code" := '';
        "Vendor No." := '';
        "Vendor Name" := '';
        "Task Type" := "Task Type"::" ";
        "No. of Resources" := 0;
        "Allocation Entries Created" := FALSE;
        "Planned Date" := 0D;
        "Client No." := '';
    end;
 
    procedure TestStatusOpen()
    var
        WorkRec: Record "Work Order Header";
    begin
        WorkRec.RESET;
        IF WorkRec.GET("Document Type","Document No.") THEN
          WorkRec.TESTFIELD("Approval Status",WorkRec."Approval Status"::Open);
    end;
 
    procedure DeleteWOResourceAllocation()
    var
        WoResAllocation: Record "WO Res. Allocation";
    begin
        WoResAllocation.RESET;
        WoResAllocation.SETRANGE("Work Order No.","Document No.");
        WoResAllocation.SETRANGE("Work Order Line No.","Document Line No.");
        IF WoResAllocation.FINDSET THEN REPEAT
          WoResAllocation.DELETE(TRUE);
        UNTIL WoResAllocation.NEXT = 0;
    end;
}


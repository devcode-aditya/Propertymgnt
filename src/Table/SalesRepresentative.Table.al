table 33016800 "Sales Representative"
{
    Caption = 'Sales Representative';
    LookupFormID = Form33016800;

    fields
    {
        field(1; "No."; Code[10])
        {
        }
        field(2; "Agent Type"; Option)
        {
            OptionCaption = 'Salesperson,Sales Agent';
            OptionMembers = Salesperson,"Sales Agent";

            trigger OnValidate()
            begin
                IF "Agent Type" <> xRec."Agent Type" THEN
                    ResetRepresentative;
            end;
        }
        field(3; "Agent No."; Code[20])
        {
            TableRelation = IF (Agent Type=CONST(Salesperson)) Salesperson/Purchaser
                            ELSE IF (Agent Type=CONST(Sales Agent)) Vendor;

            trigger OnValidate()
            var
                SalespersonRec: Record "Salesperson/Purchaser";
                VendorRec: Record Vendor;
            begin
                CASE "Agent Type" OF
                    "Agent Type"::Salesperson:
                        BEGIN
                            IF "Agent No." <> '' THEN BEGIN
                                SalespersonRec.GET("Agent No.");
                                Name := SalespersonRec.Name;
                                "Job Title" := SalespersonRec."Job Title";
                                "Phone No." := SalespersonRec."Phone No.";
                                "E-Mail" := SalespersonRec."E-Mail";
                                "Global Dimension 1 Code" := SalespersonRec."Global Dimension 1 Code";
                                "Global Dimension 2 Code" := SalespersonRec."Global Dimension 2 Code";
                                Address := '';
                                "Address 2" := '';
                                City := '';
                                "Post Code" := '';
                                "Country/Region Code" := '';
                                County := '';
                                Blocked := FALSE;
                            END ELSE
                                ResetRepresentative;
                        END;
                    "Agent Type"::"Sales Agent":
                        BEGIN
                            IF "Agent No." <> '' THEN BEGIN
                                VendorRec.GET("Agent No.");
                                Name := VendorRec.Name;
                                Address := VendorRec.Address;
                                "Address 2" := VendorRec."Address 2";
                                City := VendorRec.City;
                                "Post Code" := VendorRec."Post Code";
                                "Country/Region Code" := VendorRec."Country/Region Code";
                                County := VendorRec.County;
                                "Phone No." := VendorRec."Phone No.";
                                "Mobile No." := VendorRec."Telex No.";
                                "E-Mail" := VendorRec."E-Mail";
                                "Home Page" := VendorRec."Home Page";
                                VendorRec.CALCFIELDS(Picture);
                                Picture := VendorRec.Picture;
                                Blocked := FALSE;
                                "Global Dimension 1 Code" := VendorRec."Global Dimension 1 Code";
                                "Global Dimension 2 Code" := VendorRec."Global Dimension 2 Code";
                            END ELSE
                                ResetRepresentative;
                        END;
                END;
            end;
        }
        field(4; Name; Text[50])
        {
        }
        field(5; "Job Title"; Text[30])
        {
        }
        field(6; "Phone No."; Text[30])
        {
        }
        field(7; "Mobile No."; Text[30])
        {
        }
        field(8; "E-Mail"; Text[80])
        {
        }
        field(9; "Home Page"; Text[80])
        {
        }
        field(10; Picture; BLOB)
        {
        }
        field(11; Blocked; Boolean)
        {
        }
        field(12; "Global Dimension 1 Code"; Code[20])
        {
            CaptionClass = '1,1,1';
            TableRelation = "Dimension Value".Code WHERE(Global Dimension No.=CONST(1));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(1, "Global Dimension 1 Code");
            end;
        }
        field(13; "Global Dimension 2 Code"; Code[20])
        {
            CaptionClass = '1,1,2';
            TableRelation = "Dimension Value".Code WHERE(Global Dimension No.=CONST(2));

            trigger OnValidate()
            begin
                ValidateShortcutDimCode(2, "Global Dimension 2 Code");
            end;
        }
        field(14; "Date Filter"; Date)
        {
        }
        field(15; "No. Series"; Code[10])
        {
            TableRelation = "No. Series".Code;
        }
        field(16; Comment; Boolean)
        {
            CalcFormula = Exist("Premise Comment" WHERE(Table Name=FILTER(Agent),
                                                         No.=FIELD(No.)));
            Editable = false;
            FieldClass = FlowField;
        }
        field(17;Address;Text[50])
        {
            Caption = 'Address';
        }
        field(18;"Address 2";Text[50])
        {
            Caption = 'Address 2';
        }
        field(19;City;Text[30])
        {
            Caption = 'City';

            trigger OnLookup()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.LookUpCity(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidateCity(City,"Post Code");
            end;
        }
        field(20;"Post Code";Code[20])
        {
            Caption = 'Post Code';
            TableRelation = "Post Code";
            //This property is currently not supported
            //TestTableRelation = false;
            ValidateTableRelation = false;

            trigger OnLookup()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.LookUpPostCode(City,"Post Code",TRUE);
            end;

            trigger OnValidate()
            var
                PostCode: Record "Post Code";
            begin
                PostCode.ValidatePostCode(City,"Post Code");
            end;
        }
        field(21;"Country/Region Code";Code[10])
        {
            Caption = 'Country/Region Code';
            TableRelation = Country/Region;
        }
        field(22;County;Text[30])
        {
            Caption = 'County';
        }
    }

    keys
    {
        key(Key1;"No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnInsert()
    begin
        IF "No." = '' THEN BEGIN
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Commission Agent");
          NoSeriesMgt.InitSeries(PremiseMgtSetup."Commission Agent",xRec."No. Series",0D,"No.","No. Series");
        END;

        DimMgt.UpdateDefaultDim(
          DATABASE::"Sales Representative","No.",
          "Global Dimension 1 Code","Global Dimension 2 Code");
    end;

    var
        PremiseMgtSetup: Record "Premise Management Setup";
        DimMgt: Codeunit "408";
        NoSeriesMgt: Codeunit "396";
 
    procedure ValidateShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.ValidateDimValueCode(FieldNumber,ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::"Sales Representative","No.",FieldNumber,ShortcutDimCode);
        MODIFY;
    end;
 
    procedure LookupShortcutDimCode(FieldNumber: Integer;var ShortcutDimCode: Code[20])
    begin
        DimMgt.LookupDimValueCode(FieldNumber,ShortcutDimCode);
        DimMgt.SaveDefaultDim(DATABASE::"Sales Representative","No.",FieldNumber,ShortcutDimCode);
    end;
 
    procedure AssistEdit(OldAgentRec: Record "Sales Representative"): Boolean
    var
        AgentRec: Record "Sales Representative";
    begin
        WITH AgentRec DO BEGIN
          AgentRec := Rec;
          PremiseMgtSetup.GET;
          PremiseMgtSetup.TESTFIELD("Commission Agent");
          IF NoSeriesMgt.SelectSeries(PremiseMgtSetup."Commission Agent",OldAgentRec."No. Series","No. Series") THEN BEGIN
            NoSeriesMgt.SetSeries("No.");
            Rec := AgentRec;
            EXIT(TRUE);
          END;
        END;
    end;
 
    procedure ResetRepresentative()
    begin
        "Agent No." := '';
        Name := '';
        Address := '';
        "Address 2" := '';
        City := '';
        "Post Code" := '';
        County := '';
        "Country/Region Code" := '';
        "Job Title" := '';
        "Phone No." := '';
        "Mobile No." := '';
        "E-Mail" := '';
        "Home Page" := '';
        CLEAR(Picture);
        Blocked := FALSE;
        "Global Dimension 1 Code" := '';
        "Global Dimension 2 Code" := '';
        "Date Filter" := 0D;
    end;
}


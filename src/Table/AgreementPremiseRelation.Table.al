table 33016841 "Agreement Premise Relation"
{
    Caption = 'Agreement Premise Relation';
    LookupFormID = Form33016846;

    fields
    {
        field(1; "Agreement No."; Code[20])
        {
            NotBlank = true;
            TableRelation = "Agreement Header".No.;
        }
        field(2; "Premise No."; Code[20])
        {
            NotBlank = true;
            TableRelation = Premise.No. WHERE(Premise Status=FILTER(Vacant|Booked|On Lease),
                                               Blocked=CONST(No));

            trigger OnValidate()
            var
                Premise: Record Premise;
            begin
                IF Premise.GET("Premise No.") THEN BEGIN
                  "Premise Description" := Premise.Name;
                  "Premise/Sub-Premise" := Premise."Premise/Sub-Premise";
                  "Sub-Premise of Premise" := Premise."Sub-Premise of Premise";
                END ELSE BEGIN
                  "Premise Description" := '';
                  "Premise/Sub-Premise" := 0;
                  "Sub-Premise of Premise" := '';
                END;
            end;
        }
        field(3;"Premise Description";Text[50])
        {
        }
        field(4;"Agreement Type";Option)
        {
            OptionCaption = 'Lease,Sale';
            OptionMembers = Lease,Sale;
        }
        field(5;"Premise/Sub-Premise";Option)
        {
            OptionCaption = 'Premise,Sub-Premise';
            OptionMembers = Premise,"Sub-Premise";
        }
        field(6;"Sub-Premise of Premise";Code[20])
        {
        }
        field(7;"Agreement Status";Option)
        {
            Editable = false;
            OptionCaption = 'New,Active,Cancelled,Closed';
            OptionMembers = New,Active,Cancelled,Closed;
        }
    }

    keys
    {
        key(Key1;"Agreement Type","Agreement No.","Premise No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }

    trigger OnDelete()
    var
        AgreementRec: Record "Agreement Header";
    begin
        IF "Premise No." <> '' THEN BEGIN
          IF AgreementRec.GET("Agreement Type","Agreement No.") THEN
            AgreementRec.ValidateLinePremise(AgreementRec,"Premise No.");
          Premise.GET("Premise No.");
          IF NOT Premise."Pre-Booked" THEN BEGIN
            Premise."Premise Status" := Premise."Premise Status"::Vacant;
            Premise."Client No." := '';
            Premise."Client Name" := '';
            Premise."Client Mobile No." := '';
            Premise."Client Phone No." := '';
            Premise."Client E-Mail" := '';
            Premise."Global Dimension 1 Code" := '';
            Premise."Global Dimension 2 Code" := '';
            Premise."Agreement Type" := 0;
            Premise."Agreement No." := '';
          END;
          Premise."Pre-Booked" := FALSE;
          Premise."Pre-Booked Agreement No." := '';

          Premise.MODIFY;
        END;
    end;

    trigger OnInsert()
    var
        PremiseRelationRec: Record "Agreement Premise Relation";
        PremiseRec: Record Premise;
        MainPremise: Record Premise;
    begin
        IF "Premise No." <> '' THEN BEGIN
          Premise.GET("Premise No.");

          Premise.TESTFIELD(Blocked,FALSE);

          PremiseRelationRec.RESET;
          PremiseRelationRec.SETRANGE("Agreement Type","Agreement Type");
          PremiseRelationRec.SETRANGE("Agreement No.","Agreement No.");
          PremiseRelationRec.SETFILTER("Premise No.",'<>%1','');
          PremiseRelationRec.SETRANGE("Premise/Sub-Premise",PremiseRelationRec."Premise/Sub-Premise"::Premise);
          IF PremiseRelationRec.FINDFIRST THEN
            ERROR(Text001,PremiseRelationRec."Premise No.","Agreement Type","Agreement No.");

          IF Premise."Premise/Sub-Premise" = Premise."Premise/Sub-Premise"::Premise THEN BEGIN
            PremiseRelationRec.RESET;
            PremiseRelationRec.SETRANGE("Agreement Type","Agreement Type");
            PremiseRelationRec.SETRANGE("Agreement No.","Agreement No.");
            PremiseRelationRec.SETFILTER("Premise No.",'<>%1','');
            PremiseRelationRec.SETRANGE("Premise/Sub-Premise",PremiseRelationRec."Premise/Sub-Premise"::"Sub-Premise");
            IF PremiseRelationRec.FINDFIRST THEN
              ERROR(Text002,PremiseRelationRec."Premise No.","Agreement Type","Agreement No.");
          END ELSE IF Premise."Premise/Sub-Premise" = Premise."Premise/Sub-Premise"::"Sub-Premise" THEN BEGIN

            IF Premise."Sub-Premise of Premise" <> '' THEN BEGIN
              MainPremise.GET(Premise."Sub-Premise of Premise");
              IF MainPremise."Premise Status" <> MainPremise."Premise Status"::Vacant THEN
                ERROR(Text33016819,MainPremise."Sub-Premise of Premise");
            END;

            PremiseRelationRec.RESET;
            PremiseRelationRec.SETRANGE("Agreement Type","Agreement Type");
            PremiseRelationRec.SETRANGE("Agreement No.","Agreement No.");
            PremiseRelationRec.SETFILTER("Premise No.",'<>%1','');
            PremiseRelationRec.SETRANGE("Premise/Sub-Premise",PremiseRelationRec."Premise/Sub-Premise"::"Sub-Premise");
            IF PremiseRelationRec.FINDSET THEN
              REPEAT
                IF PremiseRec.GET(PremiseRelationRec."Premise No.") THEN BEGIN
                  IF PremiseRec."Sub-Premise of Premise" <> Premise."Sub-Premise of Premise" THEN
                    ERROR(Text003,PremiseRelationRec."Premise No.",PremiseRec."Sub-Premise of Premise","Agreement Type","Agreement No.");
                END;
              UNTIL PremiseRelationRec.NEXT = 0;
          END;

          IF Premise."Premise/Sub-Premise" = Premise."Premise/Sub-Premise"::Premise THEN BEGIN
            Premise.CheckPremiseVacant(Premise);
          END;

          IF CheckPremisePreBooked THEN BEGIN
            Premise."Pre-Booked" := TRUE;
            Premise."Pre-Booked Agreement No." := "Agreement No.";
          END ELSE BEGIN
            Premise."Premise Status" := Premise."Premise Status"::Booked;
          END;

          Premise.MODIFY;

          IF Premise."Premise/Sub-Premise" = Premise."Premise/Sub-Premise"::Premise THEN BEGIN
            ChangeSubPremiseStatus(Premise);
          END;
        END;
    end;

    trigger OnRename()
    begin
        ERROR(Text33016803);
    end;

    var
        CalcType: Option Insert,Delete,Rename;
        Premise: Record Premise;
        Text001: Label 'Main Premise %1 is already linked with Agreement Type : %2 Agreement No. : %3';
        Text002: Label 'Sub Premise %1 is already linked with Agreement Type : %2 Agreement No. : %3';
        Text003: Label 'Sub Premise %1 of Premise %2 is already linked with Agreement Type : %3 Agreement No. : %4';
        Text33016803: Label 'You cannot rename Premise/SubPremise attached with Agreement ';
        Text33016804: Label 'Premise/Sub Premise  %1 is already Prebooked with an agreement = %2 ';
        Text33016805: Label 'Premise/Sub Premise  %1 is already booked with an agreement = %2 with Agreement status = %3';
        Text33016806: Label 'Premise/Sub Premise  %1 is already booked with an agreement = %2 with Agreement Type = %3';
        Text33016819: Label 'Status of Premise %1 must be vacant';
 
    procedure UpdateAgreement(AgreeementNo: Code[20])
    var
        AgreementPremiseRec: Record "Agreement Premise Relation";
        Agreement: Record "Agreement Header";
        Premise: Record Premise;
        PremiseRec: Record Premise;
        i: Decimal;
    begin
        CLEAR(i);
        AgreementPremiseRec.RESET;
        AgreementPremiseRec.SETRANGE("Agreement No.",AgreeementNo);
        IF AgreementPremiseRec.FINDSET THEN REPEAT
          IF Premise.GET(AgreementPremiseRec."Premise No.") THEN
            i += Premise."Leasable/Salable Area";
        UNTIL AgreementPremiseRec.NEXT = 0;

        Agreement.RESET;
        Agreement.SETRANGE("No.",AgreeementNo);
        IF Agreement.FINDFIRST THEN BEGIN
          Agreement."Calculated Area" := i;
          Agreement.MODIFY;
        END;
    end;
 
    procedure CheckPremisePreBooked(): Boolean
    var
        PremiseRec: Record Premise;
        AgrmtPremiseRec: Record "Agreement Premise Relation";
        AgrmtRec: Record "Agreement Header";
        PremiseRec1: Record Premise;
    begin
        IF "Premise No." <> '' THEN
          PremiseRec.GET("Premise No.")
        ELSE
          EXIT(FALSE);

        IF PremiseRec."Allow Multiple Agreements" THEN
          EXIT(FALSE);

        IF PremiseRec."Pre-Booked" THEN
          ERROR(Text33016804,PremiseRec."No.",PremiseRec."Pre-Booked Agreement No.");

        AgrmtPremiseRec.RESET;
        AgrmtPremiseRec.SETRANGE("Premise No.",PremiseRec."No.");
        AgrmtPremiseRec.SETFILTER("Agreement No.",'<>%1',"Agreement No.");
        AgrmtPremiseRec.SETRANGE("Agreement Status",AgrmtPremiseRec."Agreement Status"::New);
        IF AgrmtPremiseRec.FINDFIRST THEN BEGIN
          ERROR(Text33016805,PremiseRec."No.",AgrmtPremiseRec."Agreement No.",AgrmtPremiseRec."Agreement Status");
          EXIT(FALSE)
        END;

        AgrmtPremiseRec.RESET;
        AgrmtPremiseRec.SETRANGE("Premise No.",PremiseRec."No.");
        AgrmtPremiseRec.SETFILTER("Agreement No.",'<>%1',"Agreement No.");
        AgrmtPremiseRec.SETRANGE("Agreement Status",AgrmtPremiseRec."Agreement Status"::Active);
        IF AgrmtPremiseRec.FINDFIRST THEN BEGIN
          IF AgrmtPremiseRec."Agreement Type" = AgrmtPremiseRec."Agreement Type"::Sale THEN
            ERROR(Text33016805,PremiseRec."No.",AgrmtPremiseRec."Agreement No.",AgrmtPremiseRec."Agreement Type")
          ELSE
            EXIT(TRUE);
        END;

        EXIT(FALSE);
    end;
 
    procedure ChangeSubPremiseStatus(PremiseR: Record Premise)
    var
        SubPremiseR: Record Premise;
    begin
        SubPremiseR.RESET;
        SubPremiseR.SETCURRENTKEY("Sub-Premise of Premise","Premise/Sub-Premise");
        SubPremiseR.SETRANGE("Sub-Premise of Premise",PremiseR."No.");
        SubPremiseR.SETRANGE("Premise/Sub-Premise",SubPremiseR."Premise/Sub-Premise"::"Sub-Premise");
        IF SubPremiseR.FINDSET THEN BEGIN
          REPEAT
           SubPremiseR.VALIDATE("Premise Status",PremiseR."Premise Status");
           SubPremiseR.MODIFY(TRUE);
          UNTIL SubPremiseR.NEXT = 0;
        END;
    end;
}


table 33016827 "Premise Comment"
{
    Caption = 'Premise Comment';
    DrillDownFormID = Form33016845;
    LookupFormID = Form33016845;

    fields
    {
        field(1; "Table Name"; Option)
        {
            OptionCaption = 'Premise,Call Register,Work Order,Agreement,Facility,Event,Agent,Insurance';
            OptionMembers = Premise,"Call Register","Work Order",Agreement,Facility,"Event",Agent,Insurance;
        }
        field(2; "No."; Code[20])
        {
            TableRelation = IF (Table Name=FILTER(Premise)) Premise.No.
                            ELSE IF (Table Name=FILTER(Call Register)) "Call Register".No.
                            ELSE IF (Table Name=FILTER(Work Order)) "Work Order Header".No.
                            ELSE IF (Table Name=FILTER(Agreement)) "Agreement Header".No.
                            ELSE IF (Table Name=FILTER(Facility)) Facility.No.
                            ELSE IF (Table Name=FILTER(Event)) "Event Detail".No.;
        }
        field(3;"Line No.";Integer)
        {
        }
        field(4;Date;Date)
        {
        }
        field(5;"Code";Code[10])
        {
        }
        field(6;Comment;Text[80])
        {
        }
        field(7;"User ID";Code[20])
        {
        }
        field(8;"Room Code";Code[10])
        {
        }
        field(9;"Event Line No.";Integer)
        {
        }
        field(10;"Print Line";Boolean)
        {
        }
    }

    keys
    {
        key(Key1;"Table Name","No.","Room Code","Event Line No.","Line No.")
        {
            Clustered = true;
        }
    }

    fieldgroups
    {
    }
 
    procedure SetUpNewLine()
    var
        CommentLine: Record "Premise Comment";
    begin
        CommentLine.SETRANGE("Table Name","Table Name");
        CommentLine.SETRANGE("No.","No.");
        CommentLine.SETRANGE(Date,WORKDATE);
        IF NOT CommentLine.FINDFIRST THEN
          Date := WORKDATE;
    end;
}


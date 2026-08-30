CREATE TABLE IF NOT EXISTS treatfeedtails.medical_notes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dog_id UUID NOT NULL REFERENCES treatfeedtails.primary_dog_details (id)
        ON DELETE CASCADE,
    medical_condition TEXT NOT NULL,
    treatment_status TEXT NOT NULL,
    started_date DATE NOT NULL,
    caretaker TEXT NOT NULL DEFAULT '',
    vet_details TEXT NOT NULL DEFAULT ''
);

CREATE INDEX IF NOT EXISTS medical_notes_dog_id_idx
    ON treatfeedtails.medical_notes (dog_id);

GRANT SELECT, INSERT, UPDATE, DELETE
    ON treatfeedtails.medical_notes TO anon, authenticated;

ALTER TABLE treatfeedtails.medical_notes ENABLE ROW LEVEL SECURITY;

CREATE POLICY "public medical notes access"
    ON treatfeedtails.medical_notes
    FOR ALL
    TO anon, authenticated
    USING (true)
    WITH CHECK (true);
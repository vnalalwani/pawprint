ALTER TABLE treatfeedtails.medical_notes
    ADD COLUMN IF NOT EXISTS treatment_given TEXT NOT NULL DEFAULT '',
    ADD COLUMN IF NOT EXISTS end_date DATE;
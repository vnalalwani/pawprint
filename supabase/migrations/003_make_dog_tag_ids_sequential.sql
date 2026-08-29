CREATE OR REPLACE FUNCTION treatfeedtails.generate_dog_tag_id()
RETURNS TEXT
LANGUAGE plpgsql
VOLATILE
AS $$
BEGIN
    RETURN 'TAG-' || LPAD(
        nextval('treatfeedtails.dog_tag_sequence')::TEXT,
        6,
        '0'
    );
END;
$$;

ALTER TABLE treatfeedtails.primary_dog_details
    ALTER COLUMN tag_id SET DEFAULT treatfeedtails.generate_dog_tag_id();

GRANT USAGE ON SEQUENCE treatfeedtails.dog_tag_sequence
    TO anon, authenticated;
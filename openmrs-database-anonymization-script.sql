-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // OpenMRS Database Anonymization Script                           //
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // MODULE: OPENMRS
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: concept_proposal_tag_map, concept_proposal, hl7_in_archive,
--        hl7_in_error, hl7_in_queue, notification_alert_recipient,
--        notification_alert, failed_events
-- strategy: truncate unnecessary tables 
-- ---------------------------------------------------------------------
SET
   FOREIGN_KEY_CHECKS = 0;
TRUNCATE TABLE concept_proposal_tag_map;
TRUNCATE TABLE concept_proposal;
TRUNCATE TABLE hl7_in_archive;
TRUNCATE TABLE hl7_in_error;
TRUNCATE TABLE hl7_in_queue;
TRUNCATE TABLE notification_alert_recipient;
TRUNCATE TABLE notification_alert;
TRUNCATE failed_events;
SET
   FOREIGN_KEY_CHECKS = 1;


-- ---------------------------------------------------------------------
-- database: openmrs
-- table: users
-- columns: username, password
-- strategy: randomize username and change user password
-- ---------------------------------------------------------------------
UPDATE
   users
SET
   username = concat( 'AnonUSR', char(round(rand()* 25) + 97), char(round(rand()* 25) + 97), char(round(rand()* 25) + 97), char(round(rand()* 25) + 97) ),
   password = '36ee23ea83437a6954bc35f6bb1ca7c564d9e096bf49180414cb3a38faca0f53be74afec961ccb0311d3125bc9310ca9cec98afa0510d2e62f2812e418b571a5',
   salt = '26a1b70790d383ffdb2f035a7f90b25794273b8a3f0104b0776db42cb4c98144c3e1e642282b2ec73b240957bcba48ca99bef1954b09d9090e681a584fd20ad7',
   secret_question = null,
   secret_answer = null
WHERE
   username NOT IN
   (
      'admin',
      'superman',
      'reports-user',
      'superman'
   )
;

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: global_property
-- columns: property_value
-- strategy: removing the username/password stored in global properties
-- ---------------------------------------------------------------------
UPDATE
   global_property
SET
   property_value = 'admin'
WHERE
   property like '%.username';
UPDATE
   global_property
SET
   property_value = 'test'
WHERE
   property like '%.password';
DELETE
FROM
   user_property
WHERE
   property NOT IN
   (
      'favouriteObsTemplates'
   )
;


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // MODULE: BAHMNI AUDIT LOGS
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: audit_log
-- strategy: truncate audit log table
-- ---------------------------------------------------------------------
TRUNCATE TABLE audit_log;


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // MODULE: BAHMNI REGISTRATION
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: patient_identifier
-- columns: patient_id, identifier
-- strategy: replace ID with new 6 integers ID
-- ---------------------------------------------------------------------
CREATE TABLE temp_patient_identifier_old(patient_id int, identifier varchar(256), PRIMARY KEY(patient_id));
INSERT INTO
   temp_patient_identifier_old
   SELECT
      patient_id,
      identifier
   FROM
      patient_identifier;
TRUNCATE patient_identifier;
INSERT INTO
   patient_identifier (patient_id, identifier, identifier_type, location_id, preferred, creator, date_created, voided, uuid)
   SELECT
      patient_id,
      concat('AN', patient_id),
      (
         Select
            patient_identifier_type_id
         FROM
            patient_identifier_type
         WHERE
            name = 'Patient Identifier'
      ),
      3,
      1,
      1,
      (
         SELECT
            timestamp(now()) - INTERVAL FLOOR( RAND( ) * 366) DAY
      ),
      0,
      uuid()
   FROM
      patient;
DROP TABLE temp_patient_identifier_old;


-- ---------------------------------------------------------------------
-- database: openmrs
-- table: person_name
-- columns: given_name, middle_name, family_name, family_name2 
-- strategy: replace person names with lorem ipsum
-- ---------------------------------------------------------------------
UPDATE
   person_name
SET
   given_name = concat( 'AnonFirstName', lipsum(1,1,FLOOR( 1 + RAND( ) *9 )) ),
   middle_name = concat( 'AnonMiddleName', lipsum(1,1,FLOOR( 1 + RAND( ) *9 )) ),
   family_name = concat( 'AnonFamilyName', lipsum(1,1,FLOOR( 1 + RAND( ) *9 )) ),
   family_name2 = concat( 'AnonFamilyName2', lipsum(1,1,FLOOR( 1 + RAND( ) *9 )) );


-- ---------------------------------------------------------------------
-- database: openmrs
-- table: person
-- column: gender
-- strategy: set opposite gender
-- ---------------------------------------------------------------------
UPDATE
   person
SET
   gender = 'F';

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: person
-- column: birthdate
-- main strategy: birthdate value is replaced with random integer values 
--                based on age group 
-- ---------------------------------------------------------------------

-- strategy: randomize +/- 6 months for persons older than ~15 yrs old
UPDATE
   person
SET
   birthdate = date_add(birthdate, interval cast(rand()* 182 - 182 as signed) day)
WHERE
   birthdate is not null
   and datediff(now(), birthdate) > 15 * 365;
   
-- strategy: randomize +/- 3 months for persons between 15 and 5 years old
UPDATE
   person
SET
   birthdate = date_add(birthdate, interval cast(rand()* 91 - 91 as signed) day)
WHERE
   birthdate is not null
   and datediff(now(), birthdate) between 15 * 365 and 5 * 365;
   
-- strategy: randomize +/- 30 days for persons less than ~5 years old
UPDATE
   person
SET
   birthdate = date_add(birthdate, interval cast(rand()* 30 - 30 as signed) day)
WHERE
   birthdate is not null
   and datediff(now(), birthdate) < 5 * 365;
UPDATE
   person
SET
   birthdate_estimated = cast(rand() as signed);
   
-- strategy: randomize the death date +/- 3 months
UPDATE
   person
SET
   death_date = date_add(death_date, interval cast(rand()* 91 - 91 as signed) day)
WHERE
   death_date is not null;


-- ---------------------------------------------------------------------
-- database: openmrs
-- table: person_address
-- columns: address1, address2, city_village, state_province, 
--          postal_code, country, latitude, longitude, country_district, 
--          address3, address4, address5, address6, address7, address8, 
--          address9, address10, address11, address12, address13, 
--          address14
-- strategy: remove and rename values
-- ---------------------------------------------------------------------
UPDATE
   person_address
SET
   address1 = concat('AnonAddress1'),
   address2 = concat('AnonAddress2'),
   address3 = concat('AnonAddress3'),
   address4 = concat('AnonAddress4'),
   address5 = concat('AnonAddress5'),
   address6 = concat('AnonAddress6'),
   address7 = concat('AnonAddress7'),
   address8 = concat('AnonAddress8'),
   address9 = concat('AnonAddress9'),
   address10 = concat('AnonAddress10'),
   address11 = concat('AnonAddress11'),
   address12 = concat('AnonAddress12'),
   address13 = concat('AnonAddress13'),
   address14 = concat('AnonAddress14'),
   county_district = concat('AnonCountyDistrict'),
   city_village = concat('AnonCityVillage'),
   country = concat('AnonCountry'),
   state_province = concat('AnonProvince'),
   postal_code = concat('AnonPostalCode'),
   latitude = null,
   longitude = null,
   date_created = now(),
   date_voided = now();


-- ---------------------------------------------------------------------
-- database: openmrs
-- table: person_attribute
-- column: value
-- strategy: randomize values with attribute prefix
-- ---------------------------------------------------------------------
DROP PROCEDURE if exists AnonymizePersonAttribute
DELIMITER //
CREATE PROCEDURE AnonymizePersonAttribute(IN person_attribute VARCHAR(255), IN attribute_format VARCHAR(255), IN randomization_prefix VARCHAR(50))
BEGIN
SET @attribute = CONCAT('%',person_attribute,'%');
	 UPDATE
    person_attribute pa
    INNER JOIN
       person_attribute_type pat
       ON pat.person_attribute_type_id = pa.person_attribute_type_id
       AND pat.name LIKE @attribute
       AND pat.format = attribute_format
  SET
      pa.value = concat(randomization_prefix, idgen());
END //

DELIMITER ;

-- AnonymizePersonAttribute(Person attribute name, attribute format, randomization prefix)
CALL AnonymizePersonAttribute('Email Address','java.lang.String','email');
CALL AnonymizePersonAttribute('Name in local language','java.lang.String','givenNameLocal');
CALL AnonymizePersonAttribute('familyNameLocal','java.lang.String','familyNameLocal');
CALL AnonymizePersonAttribute('middleNameLocal','java.lang.String','middleNameLocal');
CALL AnonymizePersonAttribute('Caste','java.lang.String','caste');
CALL AnonymizePersonAttribute('Class','org.openmrs.Concept','class');
CALL AnonymizePersonAttribute('Education Details','org.openmrs.Concept','education');
CALL AnonymizePersonAttribute('Occupation','org.openmrs.Concept','occupation');
CALL AnonymizePersonAttribute('Primary Contact','java.lang.String','primaryContact');
CALL AnonymizePersonAttribute('Secondary Contact','java.lang.String','secondaryContact');
CALL AnonymizePersonAttribute('Father/Husband Name','java.lang.String','primaryRelative');
CALL AnonymizePersonAttribute('Secondary Identifier','java.lang.String','secondaryIdentifier');
CALL AnonymizePersonAttribute('Land Holding (in acres)','java.lang.Integer','landHolding');
CALL AnonymizePersonAttribute('debt (in Rs)','java.lang.String','debt');
CALL AnonymizePersonAttribute('Distance From Center (in km)','java.lang.Float','distanceFromCenter');
CALL AnonymizePersonAttribute('Urban','java.lang.Boolean','isUrban');
CALL AnonymizePersonAttribute('cluster','org.openmrs.Concept','cluster');
CALL AnonymizePersonAttribute('Ration Card Type','org.openmrs.Concept','RationCard');
CALL AnonymizePersonAttribute('Family Income (per month in Rs)','org.openmrs.Concept','familyIncome')


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // MODULE: BAHMNI CLINICAL
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: obs
-- columns: value_text, comments
-- strategy: replace comments and values with concept datatype "text"
-- ---------------------------------------------------------------------
UPDATE
   obs
SET
   value_text = concat( 'Observation Comment - ', lipsum(2,5, RAND()) )
WHERE
   concept_id IN
   (
      SELECT
         concept_id
      FROM
         concept
      WHERE
         datatype_id = 3
   )
;
UPDATE
   obs
SET
   comments = lipsum(3,8, RAND())
WHERE
   comments is not null;

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: orders
-- columns: additional_detail
-- strategy: replace details with Lorem Ipsum and prefix
-- ---------------------------------------------------------------------
UPDATE
   conditions
SET
   additional_detail = concat( 'Conditions Additional Detail - ', lipsum(2,5, RAND()) );


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // MODULE: BAHMNI MEDICATIONS
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: orders
-- columns: comment_to_fulfiller, order_reason_non_coded
-- strategy: replace text with Lorem Ipsum and prefix
-- ---------------------------------------------------------------------
UPDATE
   orders
SET
   comment_to_fulfiller = concat( 'Order Comment - ', lipsum(2,5, RAND()) )
   order_reason_non_coded = concat( 'Order Reason Non-coded - ', lipsum(1,1,FLOOR( 1 + RAND( ) *9 )) );

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: drug_order
-- columns: dosing_instructions
-- strategy: replace text with Lorem Ipsum and prefix
-- ---------------------------------------------------------------------
UPDATE
   orders
SET
   dosing_instructions = concat( 'Dosing Instructions - ', lipsum(2,5, RAND()) );


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // MODULE: BAHMNI APPOINTMENT
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: patient_appointment
-- columns: comments
-- strategy: text value is replaced with Lorem Ipsum text 
--           containing 1-5 words and optional prefix 
-- ---------------------------------------------------------------------
UPDATE
   patient_appointment
SET
   -- lipsum(min words, max words, ipsum start)
   comments = lipsum(3,8, RAND());

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: patient_appointment_audit
-- columns: all
-- strategy: truncate audit table
-- ---------------------------------------------------------------------
TRUNCATE TABLE patient_appointment_audit;

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: provider 
-- columns: name, identifier
-- strategy: replace names with Lorem Ipsum and prefix 
--           and new identifier
-- ---------------------------------------------------------------------
UPDATE
   provider 
SET
   name = concat( 'ProviderName', lipsum(1,1,FLOOR( 1 + RAND( ) *9 )) ),
   identifier = concat( 'ProviderIdentifier', idgen());


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // MODULE: BAHMNI OPERATION THEATER
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

-- ---------------------------------------------------------------------
-- database: openmrs
-- table: surgical_appointment_attribute 
-- column: value
-- strategy: replace value with attribute prefix and random ID
-- ---------------------------------------------------------------------
DROP PROCEDURE if exists AnonymizeSurgicalAppointmentAttribute
DELIMITER //
CREATE PROCEDURE AnonymizeSurgicalAppointmentAttribute(IN surgical_appointment_attribute VARCHAR(255), IN attribute_format VARCHAR(255), IN randomization_prefix VARCHAR(50))
BEGIN
SET @attribute = CONCAT('%',surgical_appointment_attribute,'%');
	 UPDATE
    surgical_appointment_attribute saa
    INNER JOIN
       surgical_appointment_attribute_type saat
       ON saa.surgical_appointment_attribute_type_id = saat.surgical_appointment_attribute_type_id 
       AND saat.name LIKE @attribute
       AND saat.format = attribute_format
  SET
      saa.value = concat(randomization_prefix, idgen());
END //

DELIMITER ;

-- AnonymizeSurgicalAppointmentAttribute(Surgical appointment attribute name, attribute format, randomization prefix)
CALL AnonymizeSurgicalAppointmentAttribute('Procedure','java.lang.String','procedure');
CALL AnonymizeSurgicalAppointmentAttribute('Other Surgeon','org.openmrs.Provider','otherSurgeon');
CALL AnonymizeSurgicalAppointmentAttribute('Surgical Assistant','java.lang.String','surgicalAssistant');
CALL AnonymizeSurgicalAppointmentAttribute('Anaesthetist','java.lang.String','anaesthetist');
CALL AnonymizeSurgicalAppointmentAttribute('Scrub Nurse','java.lang.String','scrubNurse');
CALL AnonymizeSurgicalAppointmentAttribute('Circulating Nurse','java.lang.String','circulatingNurse');
CALL AnonymizeSurgicalAppointmentAttribute('Notes','java.lang.String','notes');


-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- // End of OpenMRS Database Anonymization Script                    //
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
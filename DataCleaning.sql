-- This project focuses on standarding the data to make it more readable and user-friendly.

select * 
from PortfolioProject..HousingData;


-- Standardize the date format to remove the extraneous information (hours, minutes, seconds)

-- What we want the date to look like
select saledate, convert(date, saledate) as formatted_date
from PortfolioProject..HousingData;

-- We need to alter and update the table

alter table PortfolioProject..HousingData
add saledate_formatted date;

update PortfolioProject..HousingData
set saledate_formatted = convert(date, saledate);

-- Now the dataset contains a new field that has the formatted date
select saledate_formatted
from PortfolioProject..HousingData;

-- Populate Property Address data
-- Some rows do not have a propertyaddress value, however, notice that there may be multiple entries
-- with the same parcelID that do have the propertyaddress in that row
-- With this in mind, we can populate the missing information by using the known information
select parcelid, propertyaddress
from PortfolioProject..HousingData
order by parcelid;

-- Use a self join to make comparisons and see which entries have a blank propertyaddress
select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress
from PortfolioProject..HousingData a 
	join PortfolioProject..HousingData b
	on a.parcelid = b.parcelid 
	and a.[UniqueID ] <> b.[UniqueID ] -- Looking at different entries
where b.propertyaddress is NULL;

-- ISNULL(what to check is null, if null what do we want to populate it with)
select a.parcelid, a.propertyaddress, b.parcelid, b.propertyaddress, ISNULL(b.propertyaddress, a.propertyaddress)
from PortfolioProject..HousingData a 
	join PortfolioProject..HousingData b
	on a.parcelid = b.parcelid 
	and a.[UniqueID ] <> b.[UniqueID ] -- Looking at different entries
where b.propertyaddress is NULL;

-- Now we want to update the dataset
update b
set propertyaddress = isnull(b.propertyaddress, a.propertyaddress)
from PortfolioProject..HousingData a 
	join PortfolioProject..HousingData b
	on a.parcelid = b.parcelid 
	and a.[UniqueID ] <> b.[UniqueID ]
where b.propertyaddress is NULL;

-- No entries have a blank propertyaddress anymore
select *
from PortfolioProject..HousingData
where propertyaddress is null;


-- Split property address into 2 individual fields (street address, city)
-- substring(field, position you are looking at, delimeter)
-- charindex(what we are looking for to split, field) returns a number, 
-- so if we do not want to include the delimeter, we subtract 1
select substring(propertyaddress, 1, charindex(',', propertyaddress) - 1) as property_street_address,
	substring(propertyaddress, charindex(',', propertyaddress) + 1, len(propertyaddress) - 1) as property_city
from PortfolioProject..HousingData;

alter table PortfolioProject..HousingData
add property_street_address nvarchar(255);

alter table PortfolioProject..HousingData
add property_city nvarchar(255);

update PortfolioProject..HousingData
set property_street_address = substring(propertyaddress, 1, charindex(',', propertyaddress) - 1);

update PortfolioProject..HousingData
set property_city = substring(propertyaddress, charindex(',', propertyaddress) + 1, len(propertyaddress) - 1);


-- Split owner address into 3 fields: street, city, state
-- PARSENAME looks for periods (we can replace it with the comma) and looks at the value backwards
select parsename(replace(owneraddress, ',', '.'), 3) as owner_state,
	parsename(replace(owneraddress, ',', '.'), 2) as owner_city,
	parsename(replace(owneraddress, ',', '.'), 1) as owner_street_address
from PortfolioProject..HousingData;

alter table PortfolioProject..HousingData
add owner_street_address nvarchar(255);

alter table PortfolioProject..HousingData
add owner_city nvarchar(255);

alter table PortfolioProject..HousingData
add owner_state nvarchar(255);

update PortfolioProject..HousingData
set owner_street_address = parsename(replace(owneraddress, ',', '.'), 3);

update PortfolioProject..HousingData
set owner_city = parsename(replace(owneraddress, ',', '.'), 2);

update PortfolioProject..HousingData
set owner_state = parsename(replace(owneraddress, ',', '.'), 1);

select *
from PortfolioProject..HousingData;


-- Change Y to Yes and N to No in "Sold as Vacant" field
-- There are 4 values for this field: Y, Yes, N, No
-- We want to make it only Yes and No
select soldasvacant,
	case
		when soldasvacant = 'Y' then 'Yes'
		when soldasvacant = 'N' then 'No'
		else soldasvacant
	end as formatted_soldasvacant
from PortfolioProject..HousingData;

update PortfolioProject..HousingData
set soldasvacant = case
		when soldasvacant = 'Y' then 'Yes'
		when soldasvacant = 'N' then 'No'
		else soldasvacant
	end;
		
-- Remove duplicate values using row number and a cte
-- This outputs the entries that are duplicates
-- Our goal is to delete these entries
with rowNumCTE as (
select *, 
	row_number() over (partition by parcelid, 
									propertyaddress, 
									saleprice,
									saledate,
									legalreference
									order by uniqueid) row_num
from PortfolioProject..HousingData
)
delete
from rowNumCTE
where row_num > 1;


-- delete unused columns (not very often, never do it to the raw data)
-- now that we split the addresses, let's delete the original address
-- and the saledate that we reformatted

alter table PortfolioProject..HousingData
drop column propertyaddress, owneraddress;

alter table PortfolioProject..HousingData
drop column saledate;

select *
from PortfolioProject..HousingData;

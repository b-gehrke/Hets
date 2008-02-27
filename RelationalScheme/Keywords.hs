{- |
Module      :  $Header$
Description :  Keywords for Relational Schemes
Copyright   :  Dominik Luecke, Uni Bremen 2008
License     :  similar to LGPL, see Hets/LICENSE.txt or LIZENZ.txt

Maintainer  :  luecke@informatik.uni-bremen.de
Stability   :  provisional
Portability :  portable

Keywords for Relational Schemes
-}

module RelationalScheme.Keywords where

import Common.Id

rsTables :: String
rsTables = "Tables"

rsTablesId :: Id
rsTablesId = stringToId rsTables

rsKey :: String
rsKey = "key"

rsKeyId :: Id
rsKeyId = stringToId rsKey

rsRelationships :: String
rsRelationships = "Relationships"

rsRelationshipsId :: Id
rsRelationshipsId = stringToId rsRelationships

rs1to1 :: String
rs1to1 = "one_to_one"

rs1to1Id :: Id
rs1to1Id = stringToId rs1to1

rs1tom :: String
rs1tom = "one_to_many"

rs1tomId :: Id
rs1tomId = stringToId rs1tom

rsmto1 :: String
rsmto1 = "many_to_one"

rsmto1Id :: Id
rsmto1Id = stringToId rsmto1

rsmtom :: String
rsmtom = "many_to_many"

rsmtomId :: Id
rsmtomId = stringToId rsmtom

rsBool :: String
rsBool = "boolean"

rsBoolId :: Id
rsBoolId = stringToId rsBool

rsBin :: String
rsBin = "binary"

rsBinId :: Id
rsBinId = stringToId rsBin

rsDate :: String
rsDate = "date"

rsDateId :: Id
rsDateId = stringToId rsDate

rsDatetime :: String
rsDatetime = "datetime"

rsDatetimeId :: Id
rsDatetimeId = stringToId rsDatetime

rsDecimal ::String
rsDecimal = "decimal"

rsDecimalId :: Id
rsDecimalId = stringToId rsDecimal

rsFloat ::String
rsFloat = "float"

rsFloatId :: Id
rsFloatId = stringToId rsFloat

rsInteger ::String
rsInteger = "integer"

rsIntegerId :: Id
rsIntegerId = stringToId rsInteger

rsString ::String
rsString = "string"

rsStringId :: Id
rsStringId = stringToId rsString

rsText :: String
rsText = "text"

rsTextId :: Id
rsTextId = stringToId rsText

rsTime :: String
rsTime = "time"

rsTimeId :: Id
rsTimeId = stringToId rsTime

rsTimestamp :: String
rsTimestamp = "timestamp"

rsTimestampId :: Id
rsTimestampId = stringToId rsTimestamp

rsDataTypes :: [String]
rsDataTypes = [rsBool, rsBin, rsDate, rsDatetime, rsDecimal, rsFloat, rsInteger,
               rsString, rsText, rsTime, rsTimestamp]

rsKeyWords :: [String]
rsKeyWords = [rsTables, rsKey, rsRelationships, rs1to1, rs1tom, rsmto1, rsmtom] ++
              rsDataTypes

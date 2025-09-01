package RelationshipConstants;
use strict;

$RelationshipConstants::CREATED   = "Created";
$RelationshipConstants::CREATEDBY = "Created by";

$RelationshipConstants::SEEALSO     = "See also";
$RelationshipConstants::ASSOCIATED  = "Associated author";
$RelationshipConstants::TRANSLATOR  = "Translator";
$RelationshipConstants::TRANSLATED  = "Translated works by";
$RelationshipConstants::ILLUSTRATOR = "Illustrator";
$RelationshipConstants::ILLUSTRATED = "Illustrated works by";

sub pluralize {
  my $name = shift;
  if (($name eq $RelationshipConstants::ASSOCIATED) ||
      ($name eq $RelationshipConstants::ILLUSTRATOR) ||
      ($name eq $RelationshipConstants::TRANSLATOR)) {
    return $name . "s";
  }
  return $name;
}

1;

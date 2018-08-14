# via http://stackoverflow.com/a/21189044/1956065
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

eval $(parse_yaml credentials.yml)
eval $(parse_yaml config.yml)

pwd=$(pwd)

# Function to apply SQL to the database configured above
function sql {
  proc=$1
  [ $# -eq 0 ] && proc=$(cat -)
  # Print colored SQL
  echo '\033[0;36m'$proc'\033[0m'
  echo $proc | psql -U $postgres__user -h $postgres__host \
                 -p $postgres__port $postgres__database
}

# Create the database - if it exists an error will be thrown which can be ignored
createdb $postgres__database -h $postgres__host -U $postgres__user -p $postgres__port

# Vanilla NLP
sql <<-EOF
DROP TABLE IF EXISTS ${app_name}_sentences_nlp;
CREATE TABLE ${app_name}_sentences_nlp (
  docid text,
  sentid integer,
  wordidx integer[],
  words text[],
  poses text[],
  ners text[],
  lemmas text[],
  dep_paths text[],
  dep_parents integer[],
  font text[],
  layout text[]
)
EOF

sql "COPY ${app_name}_sentences_nlp FROM '$pwd/input/sentences_nlp'"

# NLP352
sql <<-EOF
DROP TABLE IF EXISTS ${app_name}_sentences_nlp352;
CREATE TABLE ${app_name}_sentences_nlp352 (
  docid text,
  sentid integer,
  wordidx integer[],
  words text[],
  poses text[],
  ners text[],
  lemmas text[],
  dep_paths text[],
  dep_parents integer[]
);
EOF

sql "COPY ${app_name}_sentences_nlp352 FROM '$pwd/input/sentences_nlp352'"

# NLP352 Bazaar
sql <<-EOF
DROP TABLE IF EXISTS ${app_name}_sentences_nlp352_bazaar;
CREATE TABLE ${app_name}_sentences_nlp352_bazaar (
  docid text,
  sentid integer,
  sentence text,
  words text[],
  lemmas text[],
  poses text[],
  ners text[],
  character_position integer[],
  dep_paths text[],
  dep_parents integer[]
);
EOF

sql "COPY ${app_name}_sentences_nlp352_bazaar FROM '$pwd/input/sentences_nlp352_bazaar'"

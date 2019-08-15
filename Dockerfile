# build the Schematron XSL files from the Schematron source files
FROM hubdock/php7-apache-saxonhe AS builder

WORKDIR /build
COPY build ./

ARG JATS4R_SCHEMATRONS_VERSION=0.0.4
RUN curl -L https://github.com/JATS4R/jats-schematrons/archive/v${JATS4R_SCHEMATRONS_VERSION}.tar.gz | tar xvz
RUN php generate-xsl.php jats-schematrons-${JATS4R_SCHEMATRONS_VERSION}/schematrons/1.0/jats4r.sch jats4r.xsl

ARG SCHEMATRONS_COMMIT=0d83948ee244fd8db297201bba1d7e2b8796c511
RUN curl -L https://github.com/elifesciences/eLife-JATS-schematron/raw/${SCHEMATRONS_COMMIT}/pre-JATS-schematron.sch -o elife-schematron-pre.sch
RUN php generate-xsl.php elife-schematron-pre.sch elife-pre.xsl

RUN curl -L https://github.com/elifesciences/eLife-JATS-schematron/raw/${SCHEMATRONS_COMMIT}/final-JATS-schematron.sch -o elife-schematron-final.sch
RUN php generate-xsl.php elife-schematron-final.sch elife-final.xsl

# fetch the DTDs and copy the Schematron XSL files into place
FROM hubdock/php7-apache-saxonhe

RUN apt-get update && apt-get install -y httpry

WORKDIR /dtds
ARG DTDS_VERSION=0.0.5
ENV DTDS_VERSION=${DTDS_VERSION}
RUN curl -L https://github.com/JATS4R/jats-dtds/archive/v${DTDS_VERSION}.tar.gz | tar xvz
ENV XML_CATALOG_FILES=/dtds/jats-dtds-${DTDS_VERSION}/schema/catalog.xml

WORKDIR /var/www/html
ARG VALIDATOR_COMMIT=6478d41363d70caaa7ba89218f3a19d7bbdc3cf8
RUN curl https://raw.githubusercontent.com/elifesciences/schematron-validator/${VALIDATOR_COMMIT}/backend/schematron-validator-api/countries.xml -o countries.xml
RUN curl https://raw.githubusercontent.com/elifesciences/schematron-validator/${VALIDATOR_COMMIT}/backend/schematron-validator-api/journal-DOI.xml -o journal-DOI.xml
RUN curl https://raw.githubusercontent.com/elifesciences/schematron-validator/${VALIDATOR_COMMIT}/backend/schematron-validator-api/publisher-locations.xml -o publisher-locations.xml

COPY web/ ./
COPY --from=builder /build/*.xsl ./

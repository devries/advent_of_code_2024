FROM ghcr.io/gleam-lang/gleam:v1.7.0-erlang-slim

# Add project code
COPY . /project/

WORKDIR /project

RUN gleam build

CMD ["./runall.sh"]
  


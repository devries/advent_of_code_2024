FROM ghcr.io/gleam-lang/gleam:v1.6.3-erlang-slim

# Add project code
COPY . /project/

WORKDIR /project

RUN gleam build

CMD ["./runall.sh"]
  


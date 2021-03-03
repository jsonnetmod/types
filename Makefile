JSONNETUNIT = go run ./cmd/jsonnetunit

test:
	#$(JSONNETUNIT) ./lib/__tests__/*.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/schema.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/util.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/validerr.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/refutil.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/validator_draft7.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/validator_draft6.spec.libsonnet

dep:
	go mod download -x

prepare:
	git submodule update --remote --force;

fmt:
	jmod fmt -w ./lib/
	jmod fmt -w ./cmd/

debug: fmt
	$(JSONNETUNIT) ./lib/__tests__/schema.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/util.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/validerr.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/refutil.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/validator_draft7.spec.libsonnet
	$(JSONNETUNIT) ./lib/__tests__/validator_draft6.spec.libsonnet
	#$(JSONNETUNIT) ./lib/__tests__/validator_draft4.spec.libsonnet
	#$(JSONNETUNIT) ./lib/__tests__/validator_draft3.spec.libsonnet

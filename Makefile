DEVELOPER_KEY?=./developer_key.der
TEST_DEVICE?=vivoactive3

build:
	monkeyc -w -f ./monkey.jungle -o ./out/authenticator.prg -y $(DEVELOPER_KEY)

test: build
	monkeydo ./out/authenticator.prg $(TEST_DEVICE)

all: test
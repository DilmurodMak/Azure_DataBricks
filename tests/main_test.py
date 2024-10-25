from main import Greeter


def test_default_greeting_set():
    greeter = Greeter()
    assert greeter.message == "Hello world!"

from dummy import Greeter


def test_default_greeting_set():
    greeter = Greeter()
    assert greeter.message == "Hello From Dummy File!"
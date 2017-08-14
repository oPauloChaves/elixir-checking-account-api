# Elixir + Phoenix - Checking Account REST API

A REST API that handles operations (credit and debit) in a given checking account.

This project is using:

* [Elixir](https://elixir-lang.org) - Functional programming language
* [Phoenix Framework](http://phoenixframework.org) - An Elixir Web Framework
* [Git](https://git-scm.com) - Version Control System
* [Gitlab](https://gitlab.com) - Online Service to host and share Git repositories with the world

To get started you have to have installed on your machine [Git](https://git-scm.com) and [Erlang + Elixir](https://elixir-lang.org/install.html).

### Installing Elixir

[Follow the instruction to install Elixir on your machine](https://elixir-lang.org/install.html)

### Cloning the repository

```sh
git clone https://gitlab.com/opaulochaves/checking-account-api.git
cd checking-account-api
```

### Getting the dependencies

```sh
mix deps.get
```

### Running tests

```sh
mix test
```

> There are unit and integration tests. The tests run in parallel.

### Starting the server

```sh
mix phx.server
```

> The server is available at [localhost:4000](http://localhost:4000). I suggest you to test the API using a REST client called *Postman*.

## API

All endpoints accept and return JSON. When making requests to the API you should set a header `Accept: application/json`.

The API contains four endpoints:

### GET /accounts/:number/operations

List all operations of a checking account where account number is `:number`

Example Request:

```
GET /accounts/123/operations

{
  "data": [
    {...},
    {...}
  ]
}
```

### POST /accounts/:number/operations

Add an operations to a given account

Example Request:

```
POST /accounts/123/operations

{
  "operation": {
    "type": "deposit",
    "description": "A deposit",
    "amount": "750",
    "date": "2017-08-10T00:00:00"
  }
}
```

* `type` can be `deposit`, `salary`, `credits`, `withdrawal`, `purchase`, `debts`
* `amount` must be `> 0`
* `date` must be `<= CURRENT_DATE`

Response:

```
201 Created

{
  "data": {
    "type": "deposit",
    "number": "123",
    "description": "A deposit",
    "amount": 750,
    "date": "2017-08-10T00:00:00"
  }
}
```

### GET /accounts/:number/balance

Get the current balance of a given checking account

Example Request:

```
GET /accounts/123/balance

{
  "data": {
    "balance": 750
  }
}
```

### GET /accounts/:number/statement/:start_date/:end_date

Get the bank statement of a period of dates. It returns a list where each element
is an object containing a `date`, list of `operations` of the day, and the `balance` at the end of the day

Example Request:

```
GET /accounts/123/statement/2017-08-01/2017-08-10

{
  "data": [
    {
      "operations": [{...}],
      "date": "2017-08-10",
      "balance": 750
    }
  ]
```

### GET /accounts/:number/debts

Get the periods of debts. Returns a list of periods where each element is an object that contains `start_date`, `end_date` and `debt`

Example Request:

```
GET /accounts/123/debts

{
  "data": [
    {
      "start_date": 9999-01-01,
      "end_date": 9999-12-31,
      "debt": -999
    }
  ]
```

--------------

## Learn more

  * Official website: http://www.phoenixframework.org/
  * Guides: http://phoenixframework.org/docs/overview
  * Docs: https://hexdocs.pm/phoenix
  * Mailing list: http://groups.google.com/group/phoenix-talk
  * Source: https://github.com/phoenixframework/phoenix

-- LISTA 1 - BANCO DE DADOS II
-- Nickolas Davi Vieira Lima

-- TABELA: Clientes:

CREATE TABLE Clientes (
    ClienteID SERIAL PRIMARY KEY,
    Nome VARCHAR(100) NOT NULL,
    Email VARCHAR(100) NOT NULL,
    DataNascimento DATE NOT NULL,
    Cidade VARCHAR(50) NOT NULL
);

-- TABELA: Produtos:

CREATE TABLE Produtos (
    ProdutoID SERIAL PRIMARY KEY,
    NomeProduto VARCHAR(100) NOT NULL,
    Categoria VARCHAR(50) NOT NULL,
    Preco DECIMAL(10, 2) NOT NULL,
    Estoque INT NOT NULL
);

-- TABELA: Pedidos:

CREATE TABLE Pedidos (
    PedidoID SERIAL PRIMARY KEY,
    ClienteID INT REFERENCES Clientes(ClienteID),
    DataPedido DATE NOT NULL,
    ValorTotal DECIMAL(10, 2) NOT NULL
);

-- TABELA: ItensPedido:

CREATE TABLE ItensPedido (
    ItemID SERIAL PRIMARY KEY,
    PedidoID INT REFERENCES Pedidos(PedidoID),
    ProdutoID INT REFERENCES Produtos(ProdutoID),
    Quantidade INT NOT NULL,
    PrecoUnitario DECIMAL(10, 2) NOT NULL
);

-- QUESTÕES SOBRE FUNÇÕES (FUNCTIONS):

/*
  1. Crie uma função chamada CalcularIdade que receba a data de nascimento de um cliente
  e retorne à idade atual.
*/

CREATE OR REPLACE FUNCTION CalcularIdade(DataNascimento DATE)
RETURNS INT AS $$
BEGIN
    RETURN DATE_PART('year', AGE(DataNascimento));
END;
$$ LANGUAGE plpgsql;

/*
  2. Crie uma função chamada VerificarEstoque que receba o ProdutoID e retorne a
quantidade em estoque daquele produto.
*/

CREATE OR REPLACE FUNCTION VerificarEstoque(ProdutoID INT)
RETURNS INT AS $$
DECLARE
    quantidade_em_estoque INT;
BEGIN
    SELECT Estoque
    INTO quantidade_em_estoque
    FROM Produtos
    WHERE ProdutoID = VerificarEstoque.ProdutoID;
    
    RETURN quantidade_em_estoque;
END;
$$ LANGUAGE plpgsql;

/*
  3. Crie uma função chamada CalcularDesconto que receba o ProdutoID e um percentual de
desconto, e retorne o preço final do produto após aplicar o desconto.
*/

CREATE OR REPLACE FUNCTION CalcularDesconto(ProdutoID INT, PercentualDesconto DECIMAL)
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    preco_original DECIMAL(10, 2);
    preco_final DECIMAL(10, 2);
BEGIN
    -- Obtém o preço original do produto
    SELECT Preco
    INTO preco_original
    FROM Produtos
    WHERE ProdutoID = CalcularDesconto.ProdutoID;

    -- Calcula o preço final aplicando o desconto
    preco_final = preco_original - (preco_original * PercentualDesconto / 100);

    RETURN preco_final;
END;
$$ LANGUAGE plpgsql;

/*
  4. Crie uma função chamada ObterNomeCliente que receba o ClienteID e retorne o nome
completo do cliente.
*/

CREATE OR REPLACE FUNCTION ObterNomeCliente(ClienteID INT)
RETURNS VARCHAR(100) AS $$
DECLARE
    nome_cliente VARCHAR(100);
BEGIN
    -- Obtém o nome do cliente com base no ClienteID
    SELECT Nome
    INTO nome_cliente
    FROM Clientes
    WHERE ClienteID = ObterNomeCliente.ClienteID;

    RETURN nome_cliente;
END;
$$ LANGUAGE plpgsql;

/*
  5. Crie uma função chamada CalcularFrete que receba o valor total de um pedido e a cidade
do cliente. Se a cidade for "São Paulo", o frete deve ser 5% do valor do pedido; para outras
cidades, deve ser 10%. Use IF ELSE para definir a taxa de frete.
*/

CREATE OR REPLACE FUNCTION CalcularFrete(ValorTotal DECIMAL(10, 2), CidadeCliente VARCHAR(50))
RETURNS DECIMAL(10, 2) AS $$
DECLARE
    frete DECIMAL(10, 2);
BEGIN
    -- Calcula o frete com base na cidade
    IF CidadeCliente = 'São Paulo' THEN
        frete := ValorTotal * 0.05; -- 5% de frete para São Paulo
    ELSE
        frete := ValorTotal * 0.10; -- 10% de frete para outras cidades
    END IF;

    RETURN frete;
END;
$$ LANGUAGE plpgsql;

/*
  6. Crie uma função chamada CalcularPontos que receba um ClienteID e percorra todos os
pedidos do cliente. Para cada pedido, se o valor total for maior que R$ 100, adicione 10
pontos; se for menor ou igual, adicione 5 pontos. Retorne o total de pontos acumulados
pelo cliente. Use FOR e IF ELSE.
*/

CREATE OR REPLACE FUNCTION CalcularPontos(ClienteID INT)
RETURNS INT AS $$
DECLARE
    total_pontos INT := 0;
    valor_total DECIMAL(10, 2);
BEGIN
    -- Percorre todos os pedidos do cliente
    FOR valor_total IN
        SELECT ValorTotal
        FROM Pedidos
        WHERE ClienteID = CalcularPontos.ClienteID
    LOOP
        -- Verifica o valor do pedido e adiciona pontos
        IF valor_total > 100 THEN
            total_pontos := total_pontos + 10; -- Adiciona 10 pontos para pedidos acima de R$ 100
        ELSE
            total_pontos := total_pontos + 5;  -- Adiciona 5 pontos para pedidos de R$ 100 ou menos
        END IF;
    END LOOP;

    RETURN total_pontos;
END;
$$ LANGUAGE plpgsql;

-- QUESTÕES SOBRE PROCEDIMENTOS ARMAZENADOS (STORED PROCEDURES):

/*
  1. Crie um procedimento chamado AtualizarEstoqueEmMassa que receba uma lista de
ProdutoID e uma quantidade a ser adicionada ao estoque de cada produto. O
procedimento deve usar um loop FOR para percorrer cada ProdutoID e atualizar o estoque.
*/

CREATE OR REPLACE PROCEDURE AtualizarEstoqueEmMassa(
    ProdutoIDs INT[], 
    QuantidadeAdicionar INT
)
LANGUAGE plpgsql
AS $$
DECLARE
    produto_id INT;
BEGIN
    
    FOREACH produto_id IN ARRAY ProdutoIDs
    LOOP
        
        UPDATE Produtos
        SET Estoque = Estoque + QuantidadeAdicionar
        WHERE ProdutoID = produto_id;
    END LOOP;
END;
$$;

/*
  2. Crie um procedimento chamado InserirCliente que insira um novo cliente na tabela
Clientes.
*/

CREATE OR REPLACE PROCEDURE InserirCliente(
    p_Nome VARCHAR(100),
    p_Email VARCHAR(100),
    p_DataNascimento DATE,
    p_Cidade VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
BEGIN
    
    INSERT INTO Clientes (Nome, Email, DataNascimento, Cidade)
    VALUES (p_Nome, p_Email, p_DataNascimento, p_Cidade);
END;
$$;

/*
  3. Crie um procedimento chamado RealizarPedido que insira um novo pedido na tabela
Pedidos e os itens correspondentes na tabela ItensPedido.
*/

CREATE TYPE ItemPedidoType AS (
    ProdutoID INT,
    Quantidade INT,
    PrecoUnitario DECIMAL(10, 2)
);

CREATE OR REPLACE PROCEDURE RealizarPedido(
    p_ClienteID INT,
    p_DataPedido DATE,
    p_ItensPedido ItemPedidoType[] 
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_PedidoID INT;
    v_ValorTotal DECIMAL(10, 2) := 0;
    item ItemPedidoType; 
BEGIN
    -
    INSERT INTO Pedidos (ClienteID, DataPedido, ValorTotal)
    VALUES (p_ClienteID, p_DataPedido, 0)
    RETURNING PedidoID INTO v_PedidoID;

    FOREACH item IN ARRAY p_ItensPedido
    LOOP
        INSERT INTO ItensPedido (PedidoID, ProdutoID, Quantidade, PrecoUnitario)
        VALUES (v_PedidoID, item.ProdutoID, item.Quantidade, item.PrecoUnitario);
        
        v_ValorTotal := v_ValorTotal + (item.Quantidade * item.PrecoUnitario);
    END LOOP;

    UPDATE Pedidos
    SET ValorTotal = v_ValorTotal
    WHERE PedidoID = v_PedidoID;
END;
$$;

/*
  4. Crie um procedimento chamado ExcluirCliente que exclua um cliente da tabela Clientes e
todos os pedidos associados a esse cliente.
*/

CREATE OR REPLACE PROCEDURE ExcluirCliente(
    p_ClienteID INT
)
LANGUAGE plpgsql
AS $$
BEGIN
    
    DELETE FROM ItensPedido
    WHERE PedidoID IN (
        SELECT PedidoID
        FROM Pedidos
        WHERE ClienteID = p_ClienteID
    );

    DELETE FROM Pedidos
    WHERE ClienteID = p_ClienteID;

    DELETE FROM Clientes
    WHERE ClienteID = p_ClienteID;
END;
$$;

/*
  5. Crie um procedimento chamado AtualizarPrecoProduto que receba o ProdutoID e o novo
preço, e atualize o preço do produto na tabela Produtos.
*/

CREATE OR REPLACE PROCEDURE AtualizarPrecoProduto(
    p_ProdutoID INT,
    p_NovoPreco DECIMAL(10, 2)
)
LANGUAGE plpgsql
AS $$
BEGIN
  
    UPDATE Produtos
    SET Preco = p_NovoPreco
    WHERE ProdutoID = p_ProdutoID;
END;
$$;

/*
  6. Crie um procedimento chamado InserirClienteComVerificacao que receba os dados de
  um cliente (Nome, Email, DataNascimento, Cidade). Antes de inserir o cliente, verifique se
  o email já existe na tabela Clientes. Se existir, não insira e retorne uma mensagem de erro.
  Use DECLARE para declarar variáveis e IF ELSE para a verificação.
*/

CREATE OR REPLACE PROCEDURE InserirClienteComVerificacao(
    p_Nome VARCHAR(100),
    p_Email VARCHAR(100),
    p_DataNascimento DATE,
    p_Cidade VARCHAR(50)
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_EmailCount INT;
BEGIN
   
    SELECT COUNT(*)
    INTO v_EmailCount
    FROM Clientes
    WHERE Email = p_Email;

    IF v_EmailCount > 0 THEN
        RAISE EXCEPTION 'O email % já está cadastrado.', p_Email;
    ELSE
        INSERT INTO Clientes (Nome, Email, DataNascimento, Cidade)
        VALUES (p_Nome, p_Email, p_DataNascimento, p_Cidade);
    END IF;
END;
$$;
